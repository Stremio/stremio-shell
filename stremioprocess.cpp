#include "stremioprocess.h"

#ifdef WIN32
#include <windows.h>
#include <QDebug>
HANDLE jobMainProcess = NULL;
#endif

void Process::start(const QString &program, const QVariantList &arguments, QString mPattern) {
#ifdef WIN32
    // On windows, Child processes by default survive death of their parent, unlike on *nix
    // Only By default! We have to tell the kernel that we want something else
    // https://msdn.microsoft.com/en-us/library/windows/desktop/ms684161(v=vs.85).aspx
    // NOTE: On Windows 7 process can only belong to single job.
    // Qt Creator makes one thus you cannot debug Jobs on windows 7.
    // Nested jobs were added in Windows 8
    if (!jobMainProcess) {
        jobMainProcess = CreateJobObject(NULL, NULL);
        if(NULL == jobMainProcess)
        {
           qDebug() << "[WIN32] Could not create WIN32 Job. Node.exe will leak";
        }
        else
        {
            JOBOBJECT_EXTENDED_LIMIT_INFORMATION jeli = { 0 };
            jeli.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE |\
                    JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION;
            if(0 == SetInformationJobObject( jobMainProcess, JobObjectExtendedLimitInformation, &jeli, sizeof(jeli)))
            {
                qDebug() << "[WIN32] Failed to SetInformationJobObject";
            }
        }
    }
#endif

    QStringList args;

    // convert QVariantList from QML to QStringList for QProcess

    for (int i = 0; i < arguments.length(); i++)
        args << arguments[i].toString();

    if (!mPattern.isEmpty()) {
        this->magicPattern = mPattern.toLatin1();
        this->magicPatternFound = false;
    }

    // We will also proxy the error channel ourselves, because otherwise we have issues on Windows 7 because of
    // the lack of stderr
    //this->setProcessChannelMode(QProcess::ForwardedErrorChannel);

    QObject::connect(this, &QProcess::errorOccurred, this, &Process::onError);
    QObject::connect(this, &QProcess::readyReadStandardOutput, this, &Process::onOutput);
    QObject::connect(this, &QProcess::readyReadStandardError, this, &Process::onStdErr);
    QObject::connect(this, &QProcess::started, this, &Process::onStarted);

    QProcess::start(program, args);
}

bool Process::waitForFinished(int msecs) {
    return QProcess::waitForFinished(msecs);
}

void Process::onError(QProcess::ProcessError error) {
    this->errorThrown(error);
}

void Process::onOutput() {
    while (this->canReadLine()) {
        QByteArray line = this->readLine();
        std::cout << line.toStdString() << std::endl;
        if (!this->magicPatternFound) checkServerAddressMessage(line);
    }
}

void Process::onStdErr() {
    while (this->canReadLine()) {
        QByteArray line = this->readLine();
        std::cerr << line.toStdString() << std::endl;
    }   
}

void Process::onStarted() {
#ifdef WIN32
    // On windows, Child processes by default survive death of their parent
    // .... unless assigned to our job.
    int err = AssignProcessToJobObject(jobMainProcess, ((_PROCESS_INFORMATION*)this->pid())->hProcess);
    if (0 == err) {
        qDebug() << "[WIN32] AssignProcessToJobObject failed with code: " << err;
    };
#endif
}

void Process::checkServerAddressMessage(QByteArray message) {
    if(message.startsWith(this->magicPattern)) {
        this->magicPatternFound = true;
        addressReady(QString(message.remove(0, this->magicPattern.size())));

        // WARNING: we don't seem to be able to change process channel mode at runtime
        //QObject::disconnect(this, &QProcess::readyReadStandardOutput, this, &Process::onOutput);
        //this->setProcessChannelMode(QProcess::ForwardedChannels);
    }
}
