#ifndef SCREENSAVER_H
#define SCREENSAVER_H

#include <QtCore/QObject>

// TODO: read QtSystemInfo.ScreenSaver

#if defined(Q_OS_MAC) && !defined(Q_OS_IOS)
#import <IOKit/pwr_mgt/IOPMLib.h>
#endif

class ScreenSaver : public QObject
{
    Q_OBJECT
public:
    static ScreenSaver& instance();
    ScreenSaver();
    ~ScreenSaver();
    // enable: just restore the previous settings. settings changed during the object life will ignored
    bool enable(bool yes);
public slots:
    void enable();
    void disable();
protected:
    virtual void timerEvent(QTimerEvent *);
private:
    //return false if already called
    bool retrieveState();
    bool restoreState();
    bool state_saved, modified;
#ifdef Q_OS_LINUX
    bool isX11;
    int timeout;
    int interval;
    int preferBlanking;
    int allowExposures;
#endif //Q_OS_LINUX
    int ssTimerId; //for linux
#if defined(Q_OS_MAC) && !defined(Q_OS_IOS)
    IOPMAssertionID assertionID;
#endif
};

#endif // SCREENSAVER_H
