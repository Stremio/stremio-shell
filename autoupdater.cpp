#include <autoupdater.h>

AutoUpdater::AutoUpdater(): manager(new QNetworkAccessManager(this)) {
    init_public_key();
}

// HANDLE FATAL ERRORS
void AutoUpdater::emitFatalError(QString msg, QVariant err = QVariant()) {
    this->abort();
    emit error(msg, err);
}

// IS INSTALLED?
bool AutoUpdater::isInstalled() {

    QString dirPath = QDir::toNativeSeparators(QCoreApplication::applicationDirPath());
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();

    // Windows
    if (env.contains("LOCALAPPDATA") && dirPath.startsWith(env.value("LOCALAPPDATA"))) return true;
    if (env.contains("ProgramFiles") && dirPath.startsWith(env.value("ProgramFiles"))) return true;
    if (env.contains("ProgramFiles(x86)") && dirPath.startsWith(env.value("ProgramFiles(x86)"))) return true;

    // macOS
    if (dirPath.contains("/Applications") && dirPath.contains(".app")) return true;

    // Linux - appImage
    if (dirPath.startsWith("/tmp/.mount_")) return true;

    // Other UNIX
    // Disabled, because we cannot update those cases
    //if (dirPath.contains("/usr/bin") || dir.contains("/usr/local") || dir.contains("/opt")) return true;

    return false;
}

// WRAPPERS for public slots to make sure we execute on our thread
void AutoUpdater::checkForUpdates(QString endpoint, QString userAgent) {
    if (inProgress) return;
    inProgress = true; 
    QMetaObject::invokeMethod(this, "checkForUpdatesPerform", Qt::QueuedConnection, Q_ARG(QString, endpoint), Q_ARG(QString, userAgent));
}
void AutoUpdater::updateFromVersionDesc(QUrl versionDesc, QByteArray base64Sig) {
    if (inProgress) return;
    inProgress = true;
    QMetaObject::invokeMethod(this, "updateFromVersionDescPerform", Qt::QueuedConnection, Q_ARG(QUrl, versionDesc),
                              Q_ARG(QByteArray, base64Sig));
}
void AutoUpdater::abort() {
    QMetaObject::invokeMethod(this, "abortPerform", Qt::QueuedConnection);
}

// SETTINGS
void AutoUpdater::setForceFullUpdate(bool force) {
    forceFullUpdate = force;
}

// UTILS 
bool AutoUpdater::moveFileToAppDir(QString from) {
    QDir dir;
    QFileInfo oldFile = QFileInfo(from);
    QString dest = QCoreApplication::applicationDirPath() +  QDir::separator() + oldFile.fileName();
    
    if (! QFile::exists(from)) return false;

    if (QFile::exists(dest)) {
        if (! QFile::remove(dest)) return false;
    }

    return dir.rename(from, dest);
}

int AutoUpdater::executeCmd(QString cmd, QStringList args, bool noWait = false) {
    QProcess proc;

    proc.setProcessChannelMode(QProcess::ForwardedChannels);
    
    if (noWait) {
        proc.startDetached(cmd, args);
        return -1;
    }

    proc.start(cmd, args);

    // We mostly need quick commands executed, and waiting for them in that func removes a huge layer of complexity
    if (! proc.waitForFinished(5 * 60 * 1000)) return -1;

    return proc.exitCode();
}

// CHECK FOR UPDATES
void AutoUpdater::checkForUpdatesPerform(QString endpoint, QString userAgent)
{
    QByteArray serverHash = getFileChecksum(QCoreApplication::applicationDirPath() +  QDir::separator() + SERVER_FNAME);
    QByteArray asarHash = getFileChecksum(QCoreApplication::applicationDirPath() +  QDir::separator() + ASAR_FNAME);

    QUrl url = QUrl(endpoint);
    QUrlQuery query = QUrlQuery(url);

    query.addQueryItem("serverSum", serverHash.toHex());
    query.addQueryItem("asarSum", asarHash.toHex());
    query.addQueryItem("shellVersion", QCoreApplication::applicationVersion());

    url.setQuery(query);
    auto request = QNetworkRequest(QUrl(url));
    request.setRawHeader("User-Agent", userAgent.toUtf8());
    currentCheck = manager->get(request);
    QObject::connect(currentCheck, &QNetworkReply::finished, this, &AutoUpdater::checkForUpdatesFinished);
}

void AutoUpdater::checkForUpdatesFinished()
{
    if (currentCheck == NULL) {
        emitFatalError("internal error - currentCheck NULL on checkForUpdatesFinished");
        return;
    }

    QNetworkReply* reply = currentCheck;
    reply->deleteLater();
    currentCheck = NULL;

    if (reply->error() == QNetworkReply::NoError) {
        QJsonParseError *error = NULL;
        QJsonDocument jsonResponse = QJsonDocument::fromJson(reply->readAll(), error);

        emit checkFinished(jsonResponse.toVariant());

        if (jsonResponse.isObject()) {
            QJsonObject obj = jsonResponse.object();
            
            if (obj.value("upToDate").toBool()) {
                // NO NEW VERSION, DO NOTHING
                inProgress = false;
            } else {
                updateFromVersionDescPerform(
                    QUrl(obj.value("versionDesc").toString()),
                    QByteArray::fromBase64(obj.value("signature").toString().toUtf8())
                );
            }
        } else if (error) {
            emitFatalError("JSON parse error on checkForUpdates "+error->errorString());
        } else {
            emitFatalError("Unable to understand response from checkForUpdates");
        }

        delete error;
    } else if (reply->error() != QNetworkReply::OperationCanceledError) {
        emitFatalError("Network error on checkForUpdates "+reply->url().toString(), reply->error());
    }
}


// GET & VERIFY (SIGNATURE) VERSION DESC
void AutoUpdater::updateFromVersionDescPerform(QUrl versionDesc, QByteArray base64Sig) {
    currentCheck = manager->get(QNetworkRequest(versionDesc));
    currentCheck->setProperty("signature", base64Sig);
    QObject::connect(currentCheck, &QNetworkReply::finished, this, &AutoUpdater::updateFromVersionDescFinished);
}

void AutoUpdater::updateFromVersionDescFinished() {
    if (currentCheck == NULL) {
        emitFatalError("internal error - currentCheck NULL on updateFromVersionDescFinished");
        return;
    }

    QNetworkReply* reply = currentCheck;
    reply->deleteLater();
    currentCheck = NULL;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray dataReply = reply->readAll();
        QByteArray sig = reply->property("signature").toByteArray();

        if (verify_sig(
            (const byte*)dataReply.data(), dataReply.size(), 
            (const byte*)sig.data(), sig.length()
        ) != 0) {
            emitFatalError("Unable to verify update signature");
        } else {
            QJsonParseError *error = NULL;
            QJsonDocument jsonResponse = QJsonDocument::fromJson(dataReply, error);

            if (jsonResponse.isObject()) {
                prepareUpdate(jsonResponse);
            } else if (error) {
                emitFatalError("JSON parse error on updateFromVersionDesc "+error->errorString());
            } else {
                emitFatalError("Unable to understand response from updateFromVersionDesc");
            }

            delete error;
        }
    } else if (reply->error() != QNetworkReply::OperationCanceledError) {
        emitFatalError("Network error on updateFromVersionDesc "+reply->url().toString(), reply->error());
    }
}

// DETERMINE WHAT TO DOWNLOAD FROM versionDesc
void AutoUpdater::prepareUpdate(QJsonDocument versionDescDoc) {
    currentVersionDesc = versionDescDoc;

    QJsonObject versionDesc = versionDescDoc.object();
    QJsonObject files = versionDesc.value("files").toObject();

    QVector<QString> toDownload;
    
    if (forceFullUpdate
        || versionDesc.value("shellVersion").toString() != QCoreApplication::applicationVersion()
    ) {
        toDownload = FULL_UPDATE_FILES;
    } else {
        toDownload = PARTIAL_UPDATE_FILES;
    }

    if (! toDownload.length()) {
        emitFatalError("internal error - no files to download. Unsupported OS?");
        return;
    }

    foreach (const QString &prop, toDownload) {
        QJsonObject file = files.value(prop).toObject();

        if (! (file.contains("url") && file.contains("checksum"))) continue;

        enqueueDownload(
            QUrl(file.value("url").toString()), 
            QByteArray::fromHex(file.value("checksum").toString().toUtf8())
        );
    }

    startNextDownload();
}


// DOWNLOAD & VERIFY (CHECKSUM)
QByteArray AutoUpdater::getFileChecksum(QString path) {
    QCryptographicHash crypto(QCryptographicHash::Sha256);
    QFile file(path);
    file.open(QFile::ReadOnly);
    while (!file.atEnd()) { crypto.addData(file.read(FILE_READ_CHUNK)); }
    return crypto.result();
}

void AutoUpdater::enqueueDownload(QUrl from, QByteArray checksum) {
    downloadQueue.enqueue(fDownload(from, checksum));
}

void AutoUpdater::startNextDownload() {
    if (downloadQueue.isEmpty()) {
        inProgress = false;
        emit prepared(preparedFiles, QVariant(currentVersionDesc.object()));
        return;
    }

    fDownload next = downloadQueue.dequeue();
    QUrl url = next.first;
    QByteArray checksum = next.second;

    // WARNING: TODO: do we want to make a separate dir inside tempPath? ; we should ensure downloadFile always overrides
    QString dest = QDir::tempPath() + QDir::separator() + url.fileName();

    // Check if the download is already downloaded - could happen if we try to do a full upgrade when we've
    // already prepared one
    // Sketchy case: if the file does not exist, getFileChecksum would return the default sha256 hash; - 
    //   this would actually prevent a case where the version descriptor is generated from empty files from breaking
    // the system - because this check would return true, and then the file wouldn't exist at all, emitting an error
    // (this shouldn't be able to happen, but still...)
    if (checksum == getFileChecksum(dest)) {
        preparedFiles.push_back(dest);
        startNextDownload();
        return;
    }

    // Start the download
    output.setFileName(dest);
    if (!output.open(QIODevice::WriteOnly)) {
        emitFatalError("error opening file "+dest+" for download: "+output.errorString());
        return;
    }

    currentDownload = manager->get(QNetworkRequest(url));
    currentDownload->setProperty("checksum", checksum);
    QObject::connect(currentDownload, &QNetworkReply::readyRead, this, &AutoUpdater::downloadReadyRead);
    QObject::connect(currentDownload, &QNetworkReply::finished, this, &AutoUpdater::downloadFinished);
}

void AutoUpdater::downloadReadyRead()
{
    output.write(currentDownload->readAll());
}

void AutoUpdater::downloadFinished()
{
    output.close();

    if (currentDownload == NULL) {
        emitFatalError("internal error - currentDownload NULL on downloadFinished");
        return;
    }

    QNetworkReply* reply = currentDownload;
    reply->deleteLater();
    currentDownload = NULL;

    if (reply->error() == QNetworkReply::NoError) {
        QString dest = output.fileName();
        QByteArray checksum = reply->property("checksum").toByteArray();

        if (checksum == getFileChecksum(dest)) {
            preparedFiles.push_back(dest);
            startNextDownload();
        } else {
            emitFatalError("Unable to verify checksum for file "+dest);
        }
    } else if (reply->error() != QNetworkReply::OperationCanceledError) {
        emitFatalError("Network error on downloadFinished "+reply->url().toString(), reply->error());
    }
}


// ABORT
void AutoUpdater::abortPerform() {
    // EXPLANATION: those will be aborted, and then in the 'finished' handler, they will be deleted via ->deleteLater()
    // since the event handlers are executed in the event loop, one might think calling .checkForVer() right after
    // .abort() will re-set currentCheck before the 'finished' handler is executed
    // This is not a problem, because all public methods call the internal ones with invokeMethod and queuedConnection
    if (currentCheck) currentCheck->abort();
    if (currentDownload) currentDownload->abort();

    currentVersionDesc = QJsonDocument();

    downloadQueue = QQueue<fDownload>();
    preparedFiles = QVariantList();

    output.close();

    inProgress = false;
}
