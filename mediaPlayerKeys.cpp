#include "mediaPlayerKeys.h"

MediaPlayerKeys::MediaPlayerKeys(QObject *parent) : QObject(parent)
{
    m_interface.reset(new QDBusInterface(SERVICE_NAME,
                                         OBJECT_PATH,
                                         INTERFACE_NAME,
                                         QDBusConnection::sessionBus()));
    if (!m_interface->isValid())
    {
        qDebug("interface is invalid\n");
        qDebug("%s", qPrintable(m_interface->lastError().message()));
    }
    else
    {
        qDebug("interface is valid\n");
    }
}

void MediaPlayerKeys::releaseMediaPlayerKeys()
{
    QDBusReply<void> reply = m_interface->call("ReleaseMediaPlayerKeys", APPLICATION_NAME);
    if (!reply.isValid())
    {
        qDebug("Reply was: invalid\n");
        qDebug("%s", qPrintable(reply.error().message()));
    }

    qDebug("Reply was: valid\n");
}

void MediaPlayerKeys::grabMediaPlayerKeys()
{
    QDBusReply<void> reply = m_interface->call("GrabMediaPlayerKeys", APPLICATION_NAME, (unsigned int)0);
    if (!reply.isValid())
    {
        qDebug("Reply was: invalid\n");
        qDebug("%s", qPrintable(reply.error().message()));
    }

    qDebug("Reply was: valid\n");
}

void MediaPlayerKeys::registerToMediaPlayerKeysSignal(QObject *receiver, const char *slot)
{

    if (!QObject::connect(m_interface.data(), SIGNAL(MediaPlayerKeyPressed(QString, QString)),
                          this, SLOT(handleMediaPlayerKeyPressed(QString, QString))))
    {
        qDebug("dbus connection error:%s\n",
               qPrintable(QDBusConnection::sessionBus().lastError().message()));
    }
    else
    {
        qDebug("dbus connected");
    }

    if (!QObject::connect(this, SIGNAL(mediaPlayerKeyPressed(QVariant)),
                          receiver, slot))
    {
        qDebug("signal connection error:%s\n",
               qPrintable(QDBusConnection::sessionBus().lastError().message()));
    }
    else
    {
        qDebug("signal connected");
    }
}

void MediaPlayerKeys::handleVisibilityChange(bool visible)
{
    qDebug("handleVisibilityChange: %d\n", visible);
    if (visible)
    {
        grabMediaPlayerKeys();
    }
    else
    {
        releaseMediaPlayerKeys();
    }
}

void MediaPlayerKeys::handleMediaPlayerKeyPressed(QString appName, QString action)
{
    if (APPLICATION_NAME == appName)
    {
        emit mediaPlayerKeyPressed(action);
    }
    qDebug("handleMediaPlayerKeyPressed: %s, %s\n", qPrintable(appName), qPrintable(action));
}