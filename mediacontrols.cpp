#include "mediacontrols.h"

#ifndef Q_OS_MACOS

MediaControls::MediaControls(QObject *parent)
    : QObject(parent), m_active(false), m_playing(false), d(nullptr)
{
}

MediaControls::~MediaControls() = default;

bool MediaControls::isActive() const
{
    return m_active;
}

bool MediaControls::isPlaying() const
{
    return m_playing;
}

void MediaControls::setActive(bool active)
{
    if (m_active == active) {
        return;
    }

    m_active = active;
    Q_EMIT activeChanged();
}

void MediaControls::setPlaying(bool playing)
{
    if (m_playing == playing) {
        return;
    }

    m_playing = playing;
    Q_EMIT playingChanged();
}

void MediaControls::requestPlay()
{
    if (m_active) {
        Q_EMIT playRequested();
    }
}

void MediaControls::requestPause()
{
    if (m_active) {
        Q_EMIT pauseRequested();
    }
}

void MediaControls::requestTogglePlayPause()
{
    if (m_active) {
        Q_EMIT togglePlayPauseRequested();
    }
}

#endif // Q_OS_MACOS
