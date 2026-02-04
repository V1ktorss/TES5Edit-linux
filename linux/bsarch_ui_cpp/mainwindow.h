#pragma once

#include <QButtonGroup>
#include <QCheckBox>
#include <QComboBox>
#include <QLabel>
#include <QLineEdit>
#include <QList>
#include <QMainWindow>
#include <QPushButton>
#include <QTabWidget>
#include <QTableWidget>
#include <QToolButton>

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(const QString &bsarchBin, QWidget *parent = nullptr);

protected:
    void closeEvent(QCloseEvent *event) override;
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dropEvent(QDropEvent *event) override;

private:
    struct Entry {
        QString archive;
        QString path;
        bool hasCompressed = false;
        bool compressed = false;
    };

    QString bsarchBin_;
    QStringList archivePaths_;
    QList<Entry> allEntries_;
    QList<Entry> visibleEntries_;

    QLabel *archiveLabel_ = nullptr;

    QTabWidget *tabs_ = nullptr;
    QComboBox *extFilter_ = nullptr;
    QLineEdit *searchEdit_ = nullptr;
    QCheckBox *allFilter_ = nullptr;
    QCheckBox *compressedFilter_ = nullptr;
    QCheckBox *uncompressedFilter_ = nullptr;
    QButtonGroup *compressionFilterGroup_ = nullptr;
    QLabel *listStatusLabel_ = nullptr;

    QTableWidget *table_ = nullptr;
    QTableWidget *archiveTable_ = nullptr;
    Qt::SortOrder assetSortOrder_ = Qt::AscendingOrder;

    void setupUi();
    void appendLog(const QString &text);

    void chooseArchives();
    void setArchivePaths(const QStringList &paths);
    void updatePathLabels();
    QString activeArchive() const;

    QString runProcess(const QStringList &args, int *exitCodeOut = nullptr);
    void loadList();
    QList<Entry> parseDump(const QString &archive, const QString &output) const;
    QList<Entry> parseList(const QString &archive, const QString &output) const;
    bool isProbableEntry(const QString &line) const;

    void rebuildExtensionFilter();
    void applyFilters();
    void clearList();
    void clearSelection();
    void selectRest();
    void refreshArchiveTable();
    void sortByAssetName();
    void openSelectedEntryByDoubleClick(int row, int column);

    QString detectPackFormat(const QString &folder, const QString &archive) const;
    void extractSelection();
    void packSelected();
    void showArchiveInfo();
};
