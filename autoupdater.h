#ifndef AUTOUPDATER_H
#define AUTOUPDATER_H

#include <QCoreApplication>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDir>
#include <QFile>
#include <QThread>
#include <QUrl>
#include <QUrlQuery>
#include <QProcessEnvironment>
#include <QQueue>
#include <QVector>
#include <QProcess>
#include <QNetworkConfigurationManager>

// Mixing C and C++ :(
extern "C" {
#include <verifysig.h>
}

#define FILE_READ_CHUNK 8192

// TODO Move to somewhere? Document that we can override?
#define SERVER_FNAME "server.js"
#define ASAR_FNAME "stremio.asar"

#define PARTIAL_UPDATE_FILES { SERVER_FNAME, ASAR_FNAME }

#if defined(Q_OS_WIN)
    #define FULL_UPDATE_FILES { "windows" }
#elif defined(Q_OS_MACOS)
    #define FULL_UPDATE_FILES { "mac" }
#elif defined(Q_OS_LINUX)
    #define FULL_UPDATE_FILES { "linux" }
#else
    #define FULL_UPDATE_FILES { }
#endif

typedef QPair<QUrl, QByteArray> fDownload;

class AutoUpdater : public QObject
{
    Q_OBJECT

    public:
    AutoUpdater();

    public slots:
    bool isInstalled();
    void checkForUpdates(QString, QString);
    void updateFromVersionDesc(QUrl, QByteArray);

    void abort();

    void setForceFullUpdate(bool);

    bool moveFileToAppDir(QString);
    int executeCmd(QString, QStringList, bool);

    signals:
    void performPing();
    void networkStatus(bool);
    void error(QString, QVariant);
    void checkFinished(QVariant);
    void prepared(QVariantList, QVariant);

    private slots:
    void abortPerform();

    void checkForUpdatesPerform(QString, QString);
    void checkForUpdatesFinished();

    void updateFromVersionDescPerform(QUrl, QByteArray);
    void updateFromVersionDescFinished();

    void prepareUpdate(QJsonDocument);

    void downloadFinished();
    void downloadReadyRead();

    void emitFatalError(QString, QVariant);

    private:
    void enqueueDownload(QUrl, QByteArray);
    void startNextDownload();

    QByteArray getFileChecksum(QString);

    QNetworkAccessManager* manager = NULL;

    // State; must be reset on abort
    QJsonDocument currentVersionDesc;

    QNetworkReply* currentCheck = NULL;
    QNetworkReply* currentDownload = NULL;

    QFile output;

    // Download queue, prepared files
    QQueue<fDownload> downloadQueue;
    QVariantList preparedFiles;

    // options
    bool forceFullUpdate = false;

    // progress tracking
    bool inProgress = false;

};

#endif // AUTOUPDATER_H
