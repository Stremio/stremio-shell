#ifndef MEDIAPLAYERKEYS_H_
#define MEDIAPLAYERKEYS_H_

#include <QObject>
#include <QtDBus/QtDBus>
#include <QScopedPointer>
#include <QVariant>


#define SERVICE_NAME "org.gnome.SettingsDaemon.MediaKeys"
#define OBJECT_PATH "/org/gnome/SettingsDaemon/MediaKeys"
#define INTERFACE_NAME "org.gnome.SettingsDaemon.MediaKeys"
#define SIGNAL_NAME "MediaPlayerKeyPressed"
#define APPLICATION_NAME "stremio"

class MediaPlayerKeys : public QObject
{
    Q_OBJECT
public:
    MediaPlayerKeys(QObject *parent = 0);

    void releaseMediaPlayerKeys();
    void grabMediaPlayerKeys();

    void registerToMediaPlayerKeysSignal(QObject *receiver, const char *slot);
public slots:
    void handleVisibilityChange(bool visible);

signals:
    void mediaPlayerKeyPressed(QVariant);
private slots:
    void handleMediaPlayerKeyPressed(QString, QString);
private:
    QScopedPointer<QDBusInterface> m_interface;
};

#endif