#ifndef STREMIOPROCESS_H
#define STREMIOPROCESS_H
#include <QProcess>
#include <QVariant>
#include <QStandardPaths>
#include <QObject>
#include <iostream>

class Process : public QProcess {
    Q_OBJECT

public:
    Process(QObject *parent = 0) : QProcess(parent) { }
    Q_INVOKABLE void start(const QString &program, const QVariantList &arguments, const QString mPattern);

private:
    void checkServerAddressMessage(QByteArray message);

    QByteArray magicPattern;
    bool magicPatternFound = true; // will be set to false if we have one

private slots:
    void onError(QProcess::ProcessError error);
    void onOutput();
    void onStdErr();
    void onStarted();
    
signals:
    void addressReady(QString address);
    void errorThrown(int error);
};
#endif // STREMIOPROCESS_H
