#include "mediacontrols.h"

#ifdef Q_OS_MACOS

#import <MediaPlayer/MediaPlayer.h>

#include <QMetaObject>

@interface StremioMediaCommandTarget : NSObject
- (instancetype)initWithControls:(MediaControls *)controls;
- (MPRemoteCommandHandlerStatus)handlePlayCommand:(MPRemoteCommandEvent *)event;
- (MPRemoteCommandHandlerStatus)handlePauseCommand:(MPRemoteCommandEvent *)event;
- (MPRemoteCommandHandlerStatus)handleTogglePlayPauseCommand:(MPRemoteCommandEvent *)event;
@end

@implementation StremioMediaCommandTarget {
    MediaControls *m_controls;
}

- (instancetype)initWithControls:(MediaControls *)controls
{
    self = [super init];
    if (self) {
        m_controls = controls;
    }
    return self;
}

- (MPRemoteCommandHandlerStatus)invokeControlSlot:(const char *)slot
{
    if (!m_controls || !m_controls->isActive()) {
        return MPRemoteCommandHandlerStatusCommandFailed;
    }

    QMetaObject::invokeMethod(m_controls, slot, Qt::QueuedConnection);
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)handlePlayCommand:(MPRemoteCommandEvent *)event
{
    Q_UNUSED(event);
    return [self invokeControlSlot:"requestPlay"];
}

- (MPRemoteCommandHandlerStatus)handlePauseCommand:(MPRemoteCommandEvent *)event
{
    Q_UNUSED(event);
    return [self invokeControlSlot:"requestPause"];
}

- (MPRemoteCommandHandlerStatus)handleTogglePlayPauseCommand:(MPRemoteCommandEvent *)event
{
    Q_UNUSED(event);
    return [self invokeControlSlot:"requestTogglePlayPause"];
}

@end

class MediaControlsPrivate
{
public:
    explicit MediaControlsPrivate(MediaControls *controls)
        : commandTarget(nil)
    {
        if (@available(macOS 10.12.2, *)) {
            commandTarget = [[StremioMediaCommandTarget alloc] initWithControls:controls];

            MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
            [commandCenter.playCommand addTarget:commandTarget action:@selector(handlePlayCommand:)];
            [commandCenter.pauseCommand addTarget:commandTarget action:@selector(handlePauseCommand:)];
            [commandCenter.togglePlayPauseCommand addTarget:commandTarget action:@selector(handleTogglePlayPauseCommand:)];

            updateCommandState(false, false);
            updateNowPlaying(false, false);
        }
    }

    ~MediaControlsPrivate()
    {
        if (@available(macOS 10.12.2, *)) {
            MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
            [commandCenter.playCommand removeTarget:commandTarget action:@selector(handlePlayCommand:)];
            [commandCenter.pauseCommand removeTarget:commandTarget action:@selector(handlePauseCommand:)];
            [commandCenter.togglePlayPauseCommand removeTarget:commandTarget action:@selector(handleTogglePlayPauseCommand:)];
            updateNowPlaying(false, false);
        }

        [commandTarget release];
    }

    void updateCommandState(bool active, bool playing)
    {
        if (@available(macOS 10.12.2, *)) {
            MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
            commandCenter.playCommand.enabled = active && !playing;
            commandCenter.pauseCommand.enabled = active && playing;
            commandCenter.togglePlayPauseCommand.enabled = active;
        }
    }

    void updateNowPlaying(bool active, bool playing)
    {
        if (@available(macOS 10.12.2, *)) {
            MPNowPlayingInfoCenter *nowPlayingCenter = [MPNowPlayingInfoCenter defaultCenter];

            if (!active) {
                nowPlayingCenter.playbackState = MPNowPlayingPlaybackStateStopped;
                nowPlayingCenter.nowPlayingInfo = nil;
                return;
            }

            nowPlayingCenter.playbackState = playing
                    ? MPNowPlayingPlaybackStatePlaying
                    : MPNowPlayingPlaybackStatePaused;
            nowPlayingCenter.nowPlayingInfo = @{
                MPMediaItemPropertyTitle: @"Stremio",
                MPNowPlayingInfoPropertyPlaybackRate: @(playing ? 1.0 : 0.0)
            };
        }
    }

private:
    StremioMediaCommandTarget *commandTarget;
};

MediaControls::MediaControls(QObject *parent)
    : QObject(parent), m_active(false), m_playing(false), d(new MediaControlsPrivate(this))
{
}

MediaControls::~MediaControls()
{
    delete d;
}

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
    if (d) {
        d->updateCommandState(m_active, m_playing);
        d->updateNowPlaying(m_active, m_playing);
    }
    Q_EMIT activeChanged();
}

void MediaControls::setPlaying(bool playing)
{
    if (m_playing == playing) {
        return;
    }

    m_playing = playing;
    if (d) {
        d->updateCommandState(m_active, m_playing);
        d->updateNowPlaying(m_active, m_playing);
    }
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
