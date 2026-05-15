#include "mpris.h"

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QJsonObject>

static const char *MPRIS_OBJECT_PATH = "/org/mpris/MediaPlayer2";
static const char *PLAYER_IFACE      = "org.mpris.MediaPlayer2.Player";
static const char *SERVICE_NAME      = "org.mpris.MediaPlayer2.stremio";

// ─── MprisRootAdaptor ─────────────────────────────────────────────────────────

MprisRootAdaptor::MprisRootAdaptor(QObject *parent)
    : QDBusAbstractAdaptor(parent)
{}

void MprisRootAdaptor::Raise()
{
    QQuickItem *item = qobject_cast<QQuickItem *>(parent());
    if (!item) return;
    QQuickWindow *win = item->window();
    if (!win) return;
    win->show();
    win->raise();
    win->requestActivate();
}

// ─── MprisPlayerAdaptor ───────────────────────────────────────────────────────

MprisPlayerAdaptor::MprisPlayerAdaptor(MpvObject *player)
    : QDBusAbstractAdaptor(player), m_player(player)
{
    // Observa as propriedades mpv relevantes para MPRIS
    player->observeProperty("core-idle");
    player->observeProperty("pause");
    player->observeProperty("media-title");
    player->observeProperty("duration");
    player->observeProperty("volume");

    connect(player, &MpvObject::mpvEvent,
            this,   &MprisPlayerAdaptor::onMpvEvent);
}

QString MprisPlayerAdaptor::playbackStatus() const
{
    if (m_idle)   return "Stopped";
    if (m_paused) return "Paused";
    return "Playing";
}

QVariantMap MprisPlayerAdaptor::metadata() const
{
    QVariantMap map;
    map["mpris:trackid"] = QVariant::fromValue(
        QDBusObjectPath("/org/stremio/track/0")
    );
    if (!m_title.isEmpty())
        map["xesam:title"] = m_title;
    if (m_duration > 0.0)
        map["mpris:length"] = qlonglong(m_duration * 1e6);
    return map;
}

double MprisPlayerAdaptor::volume() const
{
    return m_player->getProperty("volume").toDouble() / 100.0;
}

void MprisPlayerAdaptor::setVolume(double v)
{
    m_player->setProperty("volume", v * 100.0);
    emitPropertiesChanged({{"Volume", v}});
}

qlonglong MprisPlayerAdaptor::position() const
{
    return qlonglong(m_player->getProperty("time-pos").toDouble() * 1e6);
}

void MprisPlayerAdaptor::PlayPause()
{
    m_player->command(QVariantList() << "cycle" << "pause");
}

void MprisPlayerAdaptor::Play()
{
    m_player->setProperty("pause", false);
}

void MprisPlayerAdaptor::Pause()
{
    m_player->setProperty("pause", true);
}

void MprisPlayerAdaptor::Stop()
{
    m_player->command(QVariantList() << "stop");
}

void MprisPlayerAdaptor::Seek(qlonglong offsetUs)
{
    m_player->command(QVariantList() << "seek" << double(offsetUs) / 1e6 << "relative");
    emit Seeked(position());
}

void MprisPlayerAdaptor::SetPosition(const QDBusObjectPath &, qlonglong positionUs)
{
    m_player->setProperty("time-pos", double(positionUs) / 1e6);
    emit Seeked(positionUs);
}

void MprisPlayerAdaptor::onMpvEvent(const QString &event, const QVariant &value)
{
    if (event == "mpv-prop-change") {
        QJsonObject obj = value.toJsonObject();
        QString     name = obj["name"].toString();
        QVariant    data = obj["data"].toVariant();

        if (name == "core-idle") {
            bool idle = data.toBool();
            if (idle != m_idle) {
                m_idle = idle;
                if (m_idle) {
                    m_title.clear();
                    m_duration = 0.0;
                }
                emitPropertiesChanged({{"PlaybackStatus", playbackStatus()}});
            }
        } else if (name == "pause") {
            bool paused = data.toBool();
            if (paused != m_paused) {
                m_paused = paused;
                emitPropertiesChanged({{"PlaybackStatus", playbackStatus()}});
            }
        } else if (name == "media-title") {
            m_title = data.toString();
            emitPropertiesChanged({{"Metadata", QVariant::fromValue(metadata())}});
        } else if (name == "duration") {
            m_duration = data.toDouble();
            emitPropertiesChanged({{"Metadata", QVariant::fromValue(metadata())}});
        } else if (name == "volume") {
            emitPropertiesChanged({{"Volume", data.toDouble() / 100.0}});
        }
    } else if (event == "mpv-event-ended") {
        m_idle  = true;
        m_title.clear();
        m_duration = 0.0;
        emitPropertiesChanged({{"PlaybackStatus", QString("Stopped")}});
    }
}

void MprisPlayerAdaptor::emitPropertiesChanged(const QVariantMap &changed)
{
    auto msg = QDBusMessage::createSignal(
        MPRIS_OBJECT_PATH,
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged"
    );
    msg << QString(PLAYER_IFACE) << changed << QStringList();
    QDBusConnection::sessionBus().send(msg);
}

// ─── Setup ────────────────────────────────────────────────────────────────────

void mprisSetup(MpvObject *player)
{
    new MprisRootAdaptor(player);
    new MprisPlayerAdaptor(player);

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerObject(MPRIS_OBJECT_PATH, player)) {
        qWarning("MPRIS: falha ao registrar objeto D-Bus em %s", MPRIS_OBJECT_PATH);
        return;
    }
    if (!bus.registerService(SERVICE_NAME)) {
        qWarning("MPRIS: falha ao registrar serviço %s", SERVICE_NAME);
        return;
    }
    qDebug("MPRIS: registrado com sucesso — KDE Connect pode controlar o Stremio");
}
