#ifndef MPRIS_H
#define MPRIS_H

#include <QtDBus/QDBusAbstractAdaptor>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusObjectPath>
#include <QVariantMap>

#include "mpv.h"

// org.mpris.MediaPlayer2 — interface raiz (identidade do player)
class MprisRootAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2")
    Q_PROPERTY(bool        CanQuit              READ canQuit)
    Q_PROPERTY(bool        CanRaise             READ canRaise)
    Q_PROPERTY(bool        HasTrackList         READ hasTrackList)
    Q_PROPERTY(QString     Identity             READ identity)
    Q_PROPERTY(QString     DesktopEntry         READ desktopEntry)
    Q_PROPERTY(QStringList SupportedUriSchemes  READ supportedUriSchemes)
    Q_PROPERTY(QStringList SupportedMimeTypes   READ supportedMimeTypes)

public:
    explicit MprisRootAdaptor(QObject *parent);

    bool        canQuit()             const { return false; }
    bool        canRaise()            const { return true; }
    bool        hasTrackList()        const { return false; }
    QString     identity()            const { return "Stremio"; }
    QString     desktopEntry()        const { return "smartcode-stremio"; }
    QStringList supportedUriSchemes() const { return {}; }
    QStringList supportedMimeTypes()  const { return {}; }

public slots:
    void Raise();
    void Quit() {}
};

// org.mpris.MediaPlayer2.Player — controle de playback
class MprisPlayerAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2.Player")
    Q_PROPERTY(QString     PlaybackStatus  READ playbackStatus)
    Q_PROPERTY(QString     LoopStatus      READ loopStatus)
    Q_PROPERTY(double      Rate            READ rate)
    Q_PROPERTY(bool        Shuffle         READ shuffle)
    Q_PROPERTY(QVariantMap Metadata        READ metadata)
    Q_PROPERTY(double      Volume          READ volume WRITE setVolume)
    Q_PROPERTY(qlonglong   Position        READ position)
    Q_PROPERTY(double      MinimumRate     READ minimumRate)
    Q_PROPERTY(double      MaximumRate     READ maximumRate)
    Q_PROPERTY(bool        CanGoNext       READ canGoNext)
    Q_PROPERTY(bool        CanGoPrevious   READ canGoPrevious)
    Q_PROPERTY(bool        CanPlay         READ canPlay)
    Q_PROPERTY(bool        CanPause        READ canPause)
    Q_PROPERTY(bool        CanSeek         READ canSeek)
    Q_PROPERTY(bool        CanControl      READ canControl)

public:
    explicit MprisPlayerAdaptor(MpvObject *player);

    QString     playbackStatus() const;
    QString     loopStatus()     const { return "None"; }
    double      rate()           const { return 1.0; }
    bool        shuffle()        const { return false; }
    QVariantMap metadata()       const;
    double      volume()         const;
    void        setVolume(double v);
    qlonglong   position()       const;
    double      minimumRate()    const { return 1.0; }
    double      maximumRate()    const { return 1.0; }
    bool        canGoNext()      const { return false; }
    bool        canGoPrevious()  const { return false; }
    bool        canPlay()        const { return true; }
    bool        canPause()       const { return true; }
    bool        canSeek()        const { return true; }
    bool        canControl()     const { return true; }

public slots:
    void PlayPause();
    void Play();
    void Pause();
    void Stop();
    void Next()     {}
    void Previous() {}
    void Seek(qlonglong offsetUs);
    void SetPosition(const QDBusObjectPath &trackId, qlonglong positionUs);
    void OpenUri(const QString &uri) { Q_UNUSED(uri) }

signals:
    void Seeked(qlonglong positionUs);

private slots:
    void onMpvEvent(const QString &event, const QVariant &value);

private:
    void emitPropertiesChanged(const QVariantMap &changed);

    MpvObject *m_player;
    bool       m_idle      = true;
    bool       m_paused    = false;
    QString    m_title;
    double     m_duration  = 0.0;
    int        m_trackSeq  = 0;
};

void mprisSetup(MpvObject *player);

#endif // MPRIS_H
