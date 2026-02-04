#include "mainwindow.h"

#include <QApplication>
#include <QFileInfo>
#include <QMessageBox>
#include <QtGlobal>

static QtMessageHandler g_prevHandler = nullptr;

static void filteredQtMessageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg) {
    if (msg.startsWith(QStringLiteral("QFont::fromString: Invalid description"))) {
        return;
    }
    if (msg.contains(QStringLiteral("Wayland does not support QWindow::requestActivate()"))) {
        return;
    }
    if (g_prevHandler) {
        g_prevHandler(type, ctx, msg);
    }
}

int main(int argc, char *argv[]) {
    g_prevHandler = qInstallMessageHandler(filteredQtMessageHandler);
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("BSArchSE"));
    app.setDesktopFileName(QStringLiteral("BSArchSE"));
    app.setOrganizationName(QStringLiteral("V1ktors"));

    QString bsarchBin = qEnvironmentVariable("BSARCH_BIN");
    if (bsarchBin.isEmpty()) {
        const QString repoRoot = QFileInfo(QString::fromUtf8(__FILE__)).absolutePath() + QStringLiteral("/../..");
        bsarchBin = QFileInfo(repoRoot + QStringLiteral("/BSArch-linux")).canonicalFilePath();
        if (bsarchBin.isEmpty()) {
            bsarchBin = repoRoot + QStringLiteral("/BSArch-linux");
        }
    }

    if (!QFileInfo::exists(bsarchBin)) {
        QMessageBox::critical(nullptr, QStringLiteral("BSArch UI"), QStringLiteral("BSArch binary not found: %1").arg(bsarchBin));
        return 1;
    }

    MainWindow w(bsarchBin);
    w.show();
    return app.exec();
}
