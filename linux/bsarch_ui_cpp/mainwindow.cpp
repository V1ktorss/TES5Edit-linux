#include "mainwindow.h"

#include <QAction>
#include <QApplication>
#include <QClipboard>
#include <QCloseEvent>
#include <QDialog>
#include <QDialogButtonBox>
#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QFormLayout>
#include <QGroupBox>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QMenu>
#include <QMessageBox>
#include <QMimeData>
#include <QProcess>
#include <QSet>
#include <QSplitter>
#include <QStatusBar>
#include <QTemporaryDir>
#include <QTextEdit>
#include <QTextStream>
#include <QUrl>
#include <QVBoxLayout>

static QString normalizedRelPath(QString p) {
    p.replace('\\', '/');
    while (p.startsWith('/')) {
        p.remove(0, 1);
    }
    return p;
}

static QString displayRelPath(QString p) {
    p = normalizedRelPath(p);
    const QString prefix = QStringLiteral("TES5Edit/");
    if (p.startsWith(prefix, Qt::CaseInsensitive)) {
        p = p.mid(prefix.size());
    }
    return p;
}

MainWindow::MainWindow(const QString &bsarchBin, QWidget *parent)
    : QMainWindow(parent), bsarchBin_(bsarchBin) {
    setWindowTitle(QStringLiteral("BSArchSE"));
    resize(1100, 760);
    setAcceptDrops(true);
    setupUi();
}

void MainWindow::setupUi() {
    auto *central = new QWidget(this);
    auto *root = new QVBoxLayout(central);
    root->setContentsMargins(8, 8, 8, 8);
    root->setSpacing(8);

    auto *headerRow = new QHBoxLayout();
    auto *menuBtn = new QToolButton(central);
    menuBtn->setText(QStringLiteral("☰"));
    auto *menu = new QMenu(menuBtn);
    menu->addAction(QStringLiteral("Archives Browse"), this, &MainWindow::chooseArchives);
    menuBtn->setMenu(menu);
    menuBtn->setPopupMode(QToolButton::InstantPopup);
    headerRow->addWidget(menuBtn);
    archiveLabel_ = new QLabel(central);
    archiveLabel_->setTextInteractionFlags(Qt::TextSelectableByMouse);
    headerRow->addWidget(archiveLabel_, 1);
    root->addLayout(headerRow);

    tabs_ = new QTabWidget(central);
    auto *fileListTab = new QWidget(tabs_);
    auto *listLayout = new QVBoxLayout(fileListTab);

    auto *toolbar = new QHBoxLayout();
    auto *loadListBtn = new QPushButton(QStringLiteral("Load List"), fileListTab);
    toolbar->addWidget(loadListBtn);
    toolbar->addWidget(new QLabel(QStringLiteral("Filter"), fileListTab));
    extFilter_ = new QComboBox(fileListTab);
    extFilter_->addItem(QStringLiteral("All"));
    toolbar->addWidget(extFilter_);
    toolbar->addWidget(new QLabel(QStringLiteral("Search"), fileListTab));
    searchEdit_ = new QLineEdit(fileListTab);
    toolbar->addWidget(searchEdit_);

    compressionFilterGroup_ = new QButtonGroup(this);
    compressionFilterGroup_->setExclusive(true);
    allFilter_ = new QCheckBox(QStringLiteral("All"), fileListTab);
    compressedFilter_ = new QCheckBox(QStringLiteral("Compressed"), fileListTab);
    uncompressedFilter_ = new QCheckBox(QStringLiteral("Uncompressed"), fileListTab);
    allFilter_->setChecked(true);
    compressionFilterGroup_->addButton(allFilter_);
    compressionFilterGroup_->addButton(compressedFilter_);
    compressionFilterGroup_->addButton(uncompressedFilter_);

    toolbar->addWidget(allFilter_);
    toolbar->addWidget(compressedFilter_);
    toolbar->addWidget(uncompressedFilter_);

    auto *restBtn = new QPushButton(QStringLiteral("Rest"), fileListTab);
    auto *clearSelBtn = new QPushButton(QStringLiteral("Clear Selection"), fileListTab);
    auto *clearListBtn = new QPushButton(QStringLiteral("Clear List"), fileListTab);
    toolbar->addWidget(restBtn);
    toolbar->addWidget(clearSelBtn);
    toolbar->addWidget(clearListBtn);
    toolbar->addStretch();
    listStatusLabel_ = new QLabel(QStringLiteral("No archive loaded."), fileListTab);
    toolbar->addWidget(listStatusLabel_);

    listLayout->addLayout(toolbar);

    table_ = new QTableWidget(fileListTab);
    table_->setColumnCount(4);
    table_->setHorizontalHeaderLabels(
        {QStringLiteral("[Compressed]"), QStringLiteral("Asset Name"), QStringLiteral("Source File"), QStringLiteral("Archive File")});
    table_->setSelectionBehavior(QAbstractItemView::SelectRows);
    table_->setSelectionMode(QAbstractItemView::ExtendedSelection);
    table_->setEditTriggers(QAbstractItemView::NoEditTriggers);
    table_->setContextMenuPolicy(Qt::CustomContextMenu);
    table_->setSortingEnabled(false);
    table_->verticalHeader()->setVisible(false);
    table_->horizontalHeader()->setSectionResizeMode(QHeaderView::Interactive);
    table_->horizontalHeader()->setStretchLastSection(false);
    table_->setColumnWidth(0, 140);
    table_->setColumnWidth(1, 320);
    table_->setColumnWidth(2, 320);
    table_->setColumnWidth(3, 260);
    listLayout->addWidget(table_);
    tabs_->addTab(fileListTab, QStringLiteral("Archive File List"));

    auto *archiveListTab = new QWidget(tabs_);
    auto *archiveListLayout = new QVBoxLayout(archiveListTab);
    archiveTable_ = new QTableWidget(archiveListTab);
    archiveTable_->setColumnCount(1);
    archiveTable_->setHorizontalHeaderLabels({QStringLiteral("Archive Path")});
    archiveTable_->horizontalHeader()->setSectionResizeMode(QHeaderView::Interactive);
    archiveTable_->horizontalHeader()->setStretchLastSection(true);
    archiveTable_->setEditTriggers(QAbstractItemView::NoEditTriggers);
    archiveTable_->setSelectionBehavior(QAbstractItemView::SelectRows);
    archiveTable_->setSelectionMode(QAbstractItemView::SingleSelection);
    archiveTable_->verticalHeader()->setVisible(false);
    archiveListLayout->addWidget(archiveTable_);
    tabs_->addTab(archiveListTab, QStringLiteral("Archive List"));

    root->addWidget(tabs_, 3);

    setCentralWidget(central);
    statusBar()->showMessage(QStringLiteral("Ready"));

    connect(loadListBtn, &QPushButton::clicked, this, &MainWindow::loadList);
    connect(extFilter_, &QComboBox::currentTextChanged, this, &MainWindow::applyFilters);
    connect(searchEdit_, &QLineEdit::textChanged, this, &MainWindow::applyFilters);
    connect(allFilter_, &QCheckBox::clicked, this, &MainWindow::applyFilters);
    connect(compressedFilter_, &QCheckBox::clicked, this, &MainWindow::applyFilters);
    connect(uncompressedFilter_, &QCheckBox::clicked, this, &MainWindow::applyFilters);
    connect(restBtn, &QPushButton::clicked, this, &MainWindow::selectRest);
    connect(clearSelBtn, &QPushButton::clicked, this, &MainWindow::clearSelection);
    connect(clearListBtn, &QPushButton::clicked, this, &MainWindow::clearList);

    connect(table_, &QTableWidget::customContextMenuRequested, this, [this](const QPoint &pos) {
        auto *menu = new QMenu(table_);
        menu->addAction(QStringLiteral("Unpack Selected"), this, &MainWindow::extractSelection);
        menu->addAction(QStringLiteral("Pack Selected"), this, &MainWindow::packSelected);
        menu->addAction(QStringLiteral("Archiv-Info"), this, &MainWindow::showArchiveInfo);
        menu->exec(table_->viewport()->mapToGlobal(pos));
        delete menu;
    });
    connect(table_->horizontalHeader(), &QHeaderView::sectionClicked, this, [this](int section) {
        if (section == 1) {
            sortByAssetName();
        }
    });
    connect(table_, &QTableWidget::cellDoubleClicked, this, &MainWindow::openSelectedEntryByDoubleClick);

    updatePathLabels();
}

void MainWindow::appendLog(const QString &text) {
    const QString oneLine = text.simplified();
    if (!oneLine.isEmpty()) {
        statusBar()->showMessage(oneLine, 6000);
    }
}

void MainWindow::chooseArchives() {
    const QStringList paths = QFileDialog::getOpenFileNames(
        this,
        QStringLiteral("Select archives"),
        QString(),
        QStringLiteral("Bethesda archives (*.bsa *.ba2);;All files (*.*)"));
    if (!paths.isEmpty()) {
        setArchivePaths(paths);
        loadList();
    }
}

void MainWindow::setArchivePaths(const QStringList &paths) {
    archivePaths_ = paths;
    updatePathLabels();
    refreshArchiveTable();
}

void MainWindow::updatePathLabels() {
    if (archivePaths_.isEmpty()) {
        archiveLabel_->setText(QStringLiteral("No archive selected"));
    } else if (archivePaths_.size() == 1) {
        archiveLabel_->setText(archivePaths_.first());
    } else {
        archiveLabel_->setText(QStringLiteral("%1 (+%2 more)").arg(archivePaths_.first()).arg(archivePaths_.size() - 1));
    }

}

void MainWindow::refreshArchiveTable() {
    archiveTable_->setRowCount(archivePaths_.size());
    for (int i = 0; i < archivePaths_.size(); ++i) {
        auto *item = new QTableWidgetItem(QFileInfo(archivePaths_[i]).fileName());
        item->setToolTip(archivePaths_[i]);
        archiveTable_->setItem(i, 0, item);
    }
}

QString MainWindow::activeArchive() const {
    return archivePaths_.isEmpty() ? QString() : archivePaths_.first();
}

QString MainWindow::runProcess(const QStringList &args, int *exitCodeOut) {
    QProcess p;
    p.start(bsarchBin_, args);
    if (!p.waitForStarted()) {
        if (exitCodeOut) {
            *exitCodeOut = -1;
        }
        return QStringLiteral("Failed to start process: %1\n").arg(bsarchBin_);
    }
    p.waitForFinished(-1);
    if (exitCodeOut) {
        *exitCodeOut = p.exitCode();
    }
    QString out = QString::fromLocal8Bit(p.readAllStandardOutput());
    out += QString::fromLocal8Bit(p.readAllStandardError());
    return out;
}

bool MainWindow::isProbableEntry(const QString &line) const {
    const QString l = line.trimmed();
    if (l.isEmpty()) {
        return false;
    }
    static const QStringList badPrefixes = {
        QStringLiteral("BSArch v"),
        QStringLiteral("Packer and unpacker"),
        QStringLiteral("The Source"),
        QStringLiteral("ARCHIVE INFO"),
        QStringLiteral("UNPACKING ARCHIVES"),
        QStringLiteral("CREATING ARCHIVES"),
        QStringLiteral("EXAMPLES"),
        QStringLiteral("Archive Name:"),
        QStringLiteral("Format:"),
        QStringLiteral("Version:"),
        QStringLiteral("Files:"),
        QStringLiteral("Archive Flags:"),
        QStringLiteral("[")
    };
    for (const auto &pfx : badPrefixes) {
        if (l.startsWith(pfx)) {
            return false;
        }
    }
    if (l.contains(':') && !l.contains('\\') && !l.contains('/')) {
        return false;
    }
    return l.contains('\\') || l.contains('/') || l.contains('.');
}

QList<MainWindow::Entry> MainWindow::parseDump(const QString &archive, const QString &output) const {
    QList<Entry> entries;
    QSet<QString> seen;
    Entry current;
    bool hasCurrent = false;

    const auto lines = output.split('\n');
    for (const QString &raw : lines) {
        const QString stripped = raw.trimmed();
        if (stripped.isEmpty()) {
            continue;
        }

        if (!raw.startsWith(' ') && (stripped.contains('\\') || stripped.contains('/'))) {
            const QString path = stripped;
            if (seen.contains(path)) {
                hasCurrent = false;
                continue;
            }
            seen.insert(path);
            current = Entry{archive, path, false, false};
            entries.append(current);
            hasCurrent = true;
            continue;
        }

        if (hasCurrent && stripped.contains(QStringLiteral("PackedSize:"))) {
            const auto parts = stripped.split(QStringLiteral("PackedSize:"));
            if (parts.size() > 1) {
                const auto val = parts[1].trimmed().split(' ').first();
                bool ok = false;
                const qlonglong packed = val.toLongLong(&ok);
                if (ok && !entries.isEmpty()) {
                    entries.last().hasCompressed = true;
                    entries.last().compressed = packed > 0;
                }
            }
        }
    }

    return entries;
}

QList<MainWindow::Entry> MainWindow::parseList(const QString &archive, const QString &output) const {
    QList<Entry> entries;
    const auto lines = output.split('\n');
    for (const QString &line : lines) {
        if (!isProbableEntry(line)) {
            continue;
        }
        entries.append(Entry{archive, line.trimmed(), false, false});
    }
    return entries;
}

void MainWindow::loadList() {
    if (archivePaths_.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Input error"), QStringLiteral("Archive path is required."));
        return;
    }

    allEntries_.clear();
    QStringList warnings;

    QApplication::setOverrideCursor(Qt::WaitCursor);
    for (const QString &archive : archivePaths_) {
        int exitCode = 0;
        const QString dumpOut = runProcess({archive, QStringLiteral("-dump")}, &exitCode);
        QList<Entry> entries;
        if (exitCode == 0) {
            entries = parseDump(archive, dumpOut);
        }
        if (entries.isEmpty()) {
            const QString listOut = runProcess({archive, QStringLiteral("-list")}, &exitCode);
            if (exitCode == 0) {
                entries = parseList(archive, listOut);
            } else {
                warnings.append(QStringLiteral("%1: list failed").arg(QFileInfo(archive).fileName()));
            }
        }
        allEntries_.append(entries);
    }
    QApplication::restoreOverrideCursor();

    rebuildExtensionFilter();
    applyFilters();

    if (!warnings.isEmpty()) {
        appendLog(QStringLiteral("\n[list warnings]\n%1\n").arg(warnings.join('\n')));
    }
}

void MainWindow::rebuildExtensionFilter() {
    QSet<QString> exts;
    for (const auto &e : allEntries_) {
        const QString ext = QFileInfo(e.path).suffix().toLower();
        if (!ext.isEmpty()) {
            exts.insert(QStringLiteral(".") + ext);
        }
    }

    QString current = extFilter_->currentText();
    extFilter_->blockSignals(true);
    extFilter_->clear();
    extFilter_->addItem(QStringLiteral("All"));
    auto list = exts.values();
    std::sort(list.begin(), list.end());
    for (const auto &ext : list) {
        extFilter_->addItem(ext);
    }
    const int idx = extFilter_->findText(current);
    extFilter_->setCurrentIndex(idx >= 0 ? idx : 0);
    extFilter_->blockSignals(false);
}

void MainWindow::applyFilters() {
    if (!allFilter_->isChecked() && !compressedFilter_->isChecked() && !uncompressedFilter_->isChecked()) {
        allFilter_->setChecked(true);
    }

    const QString ext = extFilter_->currentText().toLower();
    const QString query = searchEdit_->text().trimmed().toLower();
    const bool onlyCompressed = compressedFilter_->isChecked();
    const bool onlyUncompressed = uncompressedFilter_->isChecked();

    visibleEntries_.clear();
    for (const auto &e : allEntries_) {
        if (ext != QStringLiteral("all")) {
            const QString gotExt = QStringLiteral(".") + QFileInfo(e.path).suffix().toLower();
            if (gotExt != ext) {
                continue;
            }
        }
        if (!query.isEmpty() && !e.path.toLower().contains(query)) {
            continue;
        }
        if (onlyCompressed && (!e.hasCompressed || !e.compressed)) {
            continue;
        }
        if (onlyUncompressed && (!e.hasCompressed || e.compressed)) {
            continue;
        }
        visibleEntries_.append(e);
    }

    table_->setSortingEnabled(false);
    table_->setRowCount(visibleEntries_.size());
    for (int i = 0; i < visibleEntries_.size(); ++i) {
        const auto &e = visibleEntries_[i];
        const QString rel = displayRelPath(e.path);
        const QString tag = !e.hasCompressed ? QStringLiteral("Unknown") : (e.compressed ? QStringLiteral("Compressed") : QStringLiteral("Uncompressed"));
        const QString assetName = QFileInfo(rel).fileName();
        QString sourceDir = QFileInfo(rel).path();
        if (sourceDir == QStringLiteral(".")) {
            sourceDir.clear();
        }
        const QString archiveFile = QFileInfo(e.archive).fileName();

        auto *col0 = new QTableWidgetItem(tag);
        col0->setData(Qt::UserRole, i);
        table_->setItem(i, 0, col0);
        table_->setItem(i, 1, new QTableWidgetItem(assetName));
        table_->setItem(i, 2, new QTableWidgetItem(sourceDir));
        table_->setItem(i, 3, new QTableWidgetItem(archiveFile));
    }

    listStatusLabel_->setText(QStringLiteral("%1 / %2 files").arg(visibleEntries_.size()).arg(allEntries_.size()));
}

void MainWindow::clearList() {
    allEntries_.clear();
    visibleEntries_.clear();
    table_->setRowCount(0);
    extFilter_->clear();
    extFilter_->addItem(QStringLiteral("All"));
    searchEdit_->clear();
    allFilter_->setChecked(true);
    listStatusLabel_->setText(QStringLiteral("No archive loaded."));
}

void MainWindow::clearSelection() {
    table_->clearSelection();
}

void MainWindow::selectRest() {
    QSet<int> selected;
    for (const auto &item : table_->selectedItems()) {
        selected.insert(item->row());
    }
    for (int r = 0; r < table_->rowCount(); ++r) {
        if (!selected.contains(r)) {
            table_->selectRow(r);
        }
    }
}

QString MainWindow::detectPackFormat(const QString &folder, const QString &archive) const {
    const QString ext = QFileInfo(archive).suffix().toLower();
    const QString name = QFileInfo(archive).fileName().toLower();

    if (ext == QStringLiteral("ba2")) {
        QDirIterator it(folder, QDir::Files, QDirIterator::Subdirectories);
        bool hasFiles = false;
        bool allDds = true;
        while (it.hasNext()) {
            const QString file = it.next();
            hasFiles = true;
            if (!file.toLower().endsWith(QStringLiteral(".dds"))) {
                allDds = false;
                break;
            }
        }
        return (hasFiles && allDds) ? QStringLiteral("fo4dds") : QStringLiteral("fo4");
    }

    if (ext == QStringLiteral("bsa")) {
        if (name.contains(QStringLiteral("tes3")) || name.contains(QStringLiteral("morrowind"))) return QStringLiteral("tes3");
        if (name.contains(QStringLiteral("tes4")) || name.contains(QStringLiteral("oblivion"))) return QStringLiteral("tes4");
        if (name.contains(QStringLiteral("sse")) || name.contains(QStringLiteral("specialedition"))) return QStringLiteral("sse");
        if (name.contains(QStringLiteral("fo3"))) return QStringLiteral("fo3");
        if (name.contains(QStringLiteral("fnv")) || name.contains(QStringLiteral("newvegas"))) return QStringLiteral("fnv");
    }

    return QStringLiteral("tes5");
}

void MainWindow::extractSelection() {
    if (table_->selectedItems().isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Selection error"), QStringLiteral("Select at least one file."));
        return;
    }
    if (archivePaths_.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Input error"), QStringLiteral("Archive(s) are required."));
        return;
    }
    const QString targetRoot = QFileDialog::getExistingDirectory(this, QStringLiteral("Select target folder to unpack"));
    if (targetRoot.isEmpty()) {
        return;
    }

    QMap<QString, QStringList> byArchive;
    QSet<int> rows;
    for (const auto *item : table_->selectedItems()) {
        rows.insert(item->row());
    }
    for (int row : rows) {
        auto *rowItem = table_->item(row, 0);
        if (!rowItem) {
            continue;
        }
        const int visibleIdx = rowItem->data(Qt::UserRole).toInt();
        if (visibleIdx >= 0 && visibleIdx < visibleEntries_.size()) {
            const auto &e = visibleEntries_[visibleIdx];
            byArchive[e.archive].append(e.path);
        }
    }

    appendLog(QStringLiteral("\n$ extract-selected %1 files\n").arg(rows.size()));

    int copied = 0;
    QStringList missing;
    for (auto it = byArchive.begin(); it != byArchive.end(); ++it) {
        const QString archive = it.key();
        const QStringList selected = it.value();

        QTemporaryDir temp;
        if (!temp.isValid()) {
            appendLog(QStringLiteral("[error] Failed to create temp directory\n"));
            continue;
        }

        QStringList args{QStringLiteral("unpack"), archive, temp.path(), QStringLiteral("-q")};

        int exitCode = 0;
        const QString out = runProcess(args, &exitCode);
        appendLog(out);
        if (exitCode != 0) {
            appendLog(QStringLiteral("[error] Unpack failed for %1\n").arg(QFileInfo(archive).fileName()));
            continue;
        }

        for (const QString &rel : selected) {
            const QString relNorm = normalizedRelPath(rel);
            const QString src1 = QDir(temp.path()).filePath(rel);
            const QString src2 = QDir(temp.path()).filePath(relNorm);
            const QString src = QFileInfo::exists(src1) ? src1 : src2;
            const QString dst = QDir(targetRoot).filePath(relNorm);
            QFileInfo dstInfo(dst);
            QDir().mkpath(dstInfo.path());
            QFile::remove(dst);
            if (QFile::copy(src, dst)) {
                copied += 1;
            } else {
                missing.append(QStringLiteral("%1: %2").arg(QFileInfo(archive).fileName(), rel));
            }
        }
    }

    QMessageBox summary(this);
    summary.setWindowTitle(QStringLiteral("Unpack Selected"));
    summary.setIcon(QMessageBox::Information);
    summary.setText(QStringLiteral("Copied %1/%2 files.").arg(copied).arg(rows.size()));
    if (!missing.isEmpty()) {
        summary.setDetailedText(QStringLiteral("Missing:\n%1").arg(missing.join('\n')));
    }
    summary.exec();

}

void MainWindow::sortByAssetName() {
    table_->sortItems(1, assetSortOrder_);
    assetSortOrder_ = (assetSortOrder_ == Qt::AscendingOrder) ? Qt::DescendingOrder : Qt::AscendingOrder;
}

void MainWindow::openSelectedEntryByDoubleClick(int row, int column) {
    Q_UNUSED(column);
    auto *rowItem = table_->item(row, 0);
    if (!rowItem) {
        return;
    }
    const int visibleIdx = rowItem->data(Qt::UserRole).toInt();
    if (visibleIdx < 0 || visibleIdx >= visibleEntries_.size()) {
        return;
    }

    const auto &entry = visibleEntries_[visibleIdx];
    if (entry.archive.isEmpty() || entry.path.isEmpty()) {
        return;
    }

    const QString baseDir = QFileInfo(bsarchBin_).absolutePath();
    const QString tmpRoot = QDir(baseDir).filePath(QStringLiteral("Tmp"));
    QDir().mkpath(tmpRoot);

    QTemporaryDir tempUnpack;
    if (!tempUnpack.isValid()) {
        QMessageBox::warning(this, QStringLiteral("Open File"), QStringLiteral("Failed to create temp directory."));
        return;
    }

    int unpackExitCode = 0;
    const QString unpackOut =
        runProcess({QStringLiteral("unpack"), entry.archive, tempUnpack.path(), QStringLiteral("-q")}, &unpackExitCode);
    if (unpackExitCode != 0) {
        appendLog(unpackOut);
        QMessageBox::warning(this, QStringLiteral("Open File"), QStringLiteral("Unpack failed for selected file."));
        return;
    }

    const QString relNorm = normalizedRelPath(entry.path);
    const QString src1 = QDir(tempUnpack.path()).filePath(entry.path);
    const QString src2 = QDir(tempUnpack.path()).filePath(relNorm);
    const QString src = QFileInfo::exists(src1) ? src1 : src2;
    const QString dst = QDir(tmpRoot).filePath(relNorm);
    QFileInfo dstInfo(dst);
    QDir().mkpath(dstInfo.path());
    QFile::remove(dst);
    if (!QFile::copy(src, dst)) {
        appendLog(QStringLiteral("[error] Copy failed for double-click: %1 -> %2\n").arg(src, dst));
        QMessageBox::warning(this, QStringLiteral("Open File"), QStringLiteral("Could not extract selected file."));
        return;
    }

    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(dst))) {
        QMessageBox::warning(
            this,
            QStringLiteral("Open File"),
            QStringLiteral("File extracted to ./Tmp, but could not open with default app.\n%1").arg(dst));
    }
}

void MainWindow::packSelected() {
    if (table_->selectedItems().isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Selection error"), QStringLiteral("Select at least one file."));
        return;
    }

    QMap<QString, QStringList> byArchive;
    QSet<int> rows;
    for (const auto *item : table_->selectedItems()) {
        rows.insert(item->row());
    }
    for (int row : rows) {
        auto *rowItem = table_->item(row, 0);
        if (!rowItem) {
            continue;
        }
        const int visibleIdx = rowItem->data(Qt::UserRole).toInt();
        if (visibleIdx >= 0 && visibleIdx < visibleEntries_.size()) {
            const auto &e = visibleEntries_[visibleIdx];
            byArchive[e.archive].append(e.path);
        }
    }
    if (byArchive.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Pack Selected"), QStringLiteral("No valid selected entries."));
        return;
    }

    QDialog dlg(this);
    dlg.setWindowTitle(QStringLiteral("Pack Selected"));
    dlg.resize(560, 220);
    auto *layout = new QVBoxLayout(&dlg);
    auto *form = new QFormLayout();

    auto *outputEdit = new QLineEdit(&dlg);
    auto *browseBtn = new QPushButton(QStringLiteral("Browse"), &dlg);
    auto *outRow = new QWidget(&dlg);
    auto *outLayout = new QHBoxLayout(outRow);
    outLayout->setContentsMargins(0, 0, 0, 0);
    outLayout->addWidget(outputEdit, 1);
    outLayout->addWidget(browseBtn);
    form->addRow(QStringLiteral("Output Archive"), outRow);

    auto *formatBox = new QComboBox(&dlg);
    formatBox->addItems({QStringLiteral("Auto"), QStringLiteral("tes3"), QStringLiteral("tes4"), QStringLiteral("fo3"),
                         QStringLiteral("fnv"), QStringLiteral("tes5"), QStringLiteral("sse"), QStringLiteral("fo4"),
                         QStringLiteral("fo4dds"), QStringLiteral("sf1"), QStringLiteral("sf1dds")});
    form->addRow(QStringLiteral("Format"), formatBox);

    auto *compressCheck = new QCheckBox(QStringLiteral("Compress (-z)"), &dlg);
    auto *shareCheck = new QCheckBox(QStringLiteral("Share (-share)"), &dlg);
    auto *mtCheck = new QCheckBox(QStringLiteral("Multi-thread (-mt)"), &dlg);
    auto *flagsRow = new QWidget(&dlg);
    auto *flagsLayout = new QHBoxLayout(flagsRow);
    flagsLayout->setContentsMargins(0, 0, 0, 0);
    flagsLayout->addWidget(compressCheck);
    flagsLayout->addWidget(shareCheck);
    flagsLayout->addWidget(mtCheck);
    flagsLayout->addStretch();
    form->addRow(QStringLiteral("Options"), flagsRow);

    layout->addLayout(form);
    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, &dlg);
    layout->addWidget(buttons);

    QObject::connect(browseBtn, &QPushButton::clicked, &dlg, [outputEdit, &dlg]() {
        const QString path = QFileDialog::getSaveFileName(
            &dlg,
            QStringLiteral("Choose output archive"),
            QString(),
            QStringLiteral("BSA archive (*.bsa);;BA2 archive (*.ba2);;All files (*.*)"));
        if (!path.isEmpty()) {
            outputEdit->setText(path);
        }
    });
    QObject::connect(buttons, &QDialogButtonBox::accepted, &dlg, &QDialog::accept);
    QObject::connect(buttons, &QDialogButtonBox::rejected, &dlg, &QDialog::reject);

    if (dlg.exec() != QDialog::Accepted) {
        return;
    }

    const QString outArchive = outputEdit->text().trimmed();
    if (outArchive.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Pack Selected"), QStringLiteral("Output archive is required."));
        return;
    }

    QTemporaryDir staging;
    if (!staging.isValid()) {
        QMessageBox::warning(this, QStringLiteral("Pack Selected"), QStringLiteral("Failed to create staging directory."));
        return;
    }

    appendLog(QStringLiteral("\n$ pack-selected %1 files -> %2\n").arg(rows.size()).arg(outArchive));

    for (auto it = byArchive.begin(); it != byArchive.end(); ++it) {
        const QString archive = it.key();
        const QStringList selected = it.value();

        QTemporaryDir tempUnpack;
        if (!tempUnpack.isValid()) {
            appendLog(QStringLiteral("[error] Failed to create unpack temp directory\n"));
            continue;
        }

        QStringList unpackArgs{QStringLiteral("unpack"), archive, tempUnpack.path(), QStringLiteral("-q")};
        if (mtCheck->isChecked()) {
            unpackArgs << QStringLiteral("-mt");
        }
        int unpackExitCode = 0;
        const QString unpackOut = runProcess(unpackArgs, &unpackExitCode);
        appendLog(unpackOut);
        if (unpackExitCode != 0) {
            appendLog(QStringLiteral("[error] Unpack failed for %1\n").arg(QFileInfo(archive).fileName()));
            continue;
        }

        for (const QString &rel : selected) {
            const QString relNorm = normalizedRelPath(rel);
            const QString src1 = QDir(tempUnpack.path()).filePath(rel);
            const QString src2 = QDir(tempUnpack.path()).filePath(relNorm);
            const QString src = QFileInfo::exists(src1) ? src1 : src2;
            const QString dst = QDir(staging.path()).filePath(relNorm);
            QFileInfo dstInfo(dst);
            QDir().mkpath(dstInfo.path());
            QFile::remove(dst);
            if (!QFile::copy(src, dst)) {
                appendLog(QStringLiteral("[warn] Missing for pack: %1 (%2)\n").arg(rel, QFileInfo(archive).fileName()));
            }
        }
    }

    QString fmt = formatBox->currentText();
    if (fmt == QStringLiteral("Auto")) {
        fmt = detectPackFormat(staging.path(), outArchive);
    }
    QStringList packArgs{QStringLiteral("pack"), staging.path(), outArchive, QStringLiteral("-") + fmt};
    if (compressCheck->isChecked()) {
        packArgs << QStringLiteral("-z");
    }
    if (shareCheck->isChecked()) {
        packArgs << QStringLiteral("-share");
    }
    if (mtCheck->isChecked()) {
        packArgs << QStringLiteral("-mt");
    }

    int packExitCode = 0;
    appendLog(QStringLiteral("Pack command started"));
    const QString packOut = runProcess(packArgs, &packExitCode);
    QMessageBox packResult(this);
    packResult.setWindowTitle(QStringLiteral("Pack Selected"));
    packResult.setIcon(packExitCode == 0 ? QMessageBox::Information : QMessageBox::Warning);
    packResult.setText(QStringLiteral("Pack finished with exit code %1.").arg(packExitCode));
    packResult.setDetailedText(packOut);
    packResult.exec();
}

void MainWindow::showArchiveInfo() {
    QString archive;
    const auto selected = table_->selectedItems();
    if (!selected.isEmpty()) {
        const int row = selected.first()->row();
        auto *rowItem = table_->item(row, 0);
        if (rowItem) {
            const int visibleIdx = rowItem->data(Qt::UserRole).toInt();
            if (visibleIdx >= 0 && visibleIdx < visibleEntries_.size()) {
                archive = visibleEntries_[visibleIdx].archive;
            }
        }
    }
    if (archive.isEmpty()) {
        archive = activeArchive();
    }
    if (archive.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Archiv-Info"), QStringLiteral("No archive selected."));
        return;
    }

    int exitCode = 0;
    const QString out = runProcess({archive, QStringLiteral("-dump")}, &exitCode);
    auto *dlg = new QDialog(this);
    dlg->setWindowTitle(QStringLiteral("Archiv-Info"));
    dlg->resize(860, 620);
    auto *layout = new QVBoxLayout(dlg);
    auto *txt = new QTextEdit(dlg);
    txt->setReadOnly(true);
    txt->setPlainText(QStringLiteral("$ %1 %2 -dump\n\n%3\n[exit %4]\n")
                          .arg(bsarchBin_, archive, out, QString::number(exitCode)));
    layout->addWidget(txt);
    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Close, dlg);
    QObject::connect(buttons, &QDialogButtonBox::rejected, dlg, &QDialog::reject);
    layout->addWidget(buttons);
    dlg->exec();
}

void MainWindow::closeEvent(QCloseEvent *event) {
    const QString baseDir = QFileInfo(bsarchBin_).absolutePath();
    const QString tmpRoot = QDir(baseDir).filePath(QStringLiteral("Tmp"));
    QDir tmpDir(tmpRoot);
    if (tmpDir.exists()) {
        tmpDir.removeRecursively();
    }
    QMainWindow::closeEvent(event);
}

void MainWindow::dragEnterEvent(QDragEnterEvent *event) {
    if (!event->mimeData()->hasUrls()) {
        event->ignore();
        return;
    }
    for (const QUrl &url : event->mimeData()->urls()) {
        const QString path = url.toLocalFile().toLower();
        if (path.endsWith(QStringLiteral(".bsa")) || path.endsWith(QStringLiteral(".ba2"))) {
            event->acceptProposedAction();
            return;
        }
    }
    event->ignore();
}

void MainWindow::dropEvent(QDropEvent *event) {
    if (!event->mimeData()->hasUrls()) {
        return;
    }

    QStringList paths;
    for (const QUrl &url : event->mimeData()->urls()) {
        const QString p = url.toLocalFile();
        if (p.toLower().endsWith(QStringLiteral(".bsa")) || p.toLower().endsWith(QStringLiteral(".ba2"))) {
            paths << p;
        }
    }
    if (!paths.isEmpty()) {
        setArchivePaths(paths);
        loadList();
    }
}
