#ifndef MEDIACONTROLS_H
#define MEDIACONTROLS_H

#include <QObject>

class MediaControlsPrivate;

class MediaControls : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool playing READ isPlaying WRITE setPlaying NOTIFY playingChanged)

public:
    explicit MediaControls(QObject *parent = nullptr);
    ~MediaControls() override;

    bool isActive() const;
    bool isPlaying() const;

public slots:
    void setActive(bool active);
    void setPlaying(bool playing);
    void requestPlay();
    void requestPause();
    void requestTogglePlayPause();

signals:
    void activeChanged();
    void playingChanged();
    void playRequested();
    void pauseRequested();
    void togglePlayPauseRequested();

private:
    bool m_active;
    bool m_playing;
    MediaControlsPrivate *d;
};

#endif // MEDIACONTROLS_H
