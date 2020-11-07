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
    // enable: just restore the previous settings. settings changed during the object life will ignored
    bool enable(bool yes);
public slots:
    void enable();
    void disable();
private:
#ifdef Q_OS_LINUX
    uint32_t cookieID;
#endif //Q_OS_LINUX
#if defined(Q_OS_MAC) && !defined(Q_OS_IOS)
    IOPMAssertionID assertionID;
#endif
};

#endif // SCREENSAVER_H
