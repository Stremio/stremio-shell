#include "screensaver.h"
#include <QtCore/QLibrary>
#ifdef Q_OS_LINUX
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusReply>
static QDBusInterface screenSaverInterface("org.freedesktop.ScreenSaver", 
           "/org/freedesktop/ScreenSaver", "org.freedesktop.ScreenSaver");
#endif //Q_OS_LINUX
#if defined(Q_OS_MAC) && !defined(Q_OS_IOS)
//http://www.cocoachina.com/macdev/cocoa/2010/0201/453.html
#include <CoreServices/CoreServices.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#endif //Q_OS_MAC
#ifdef Q_OS_WIN
#include <QAbstractEventDispatcher>
#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
#include <QAbstractNativeEventFilter>
#endif
//mingw gcc4.4 EXECUTION_STATE
#ifdef __MINGW32__
#ifndef _WIN32_WINDOWS
#define _WIN32_WINDOWS 0x0410
#endif //_WIN32_WINDOWS
#endif //__MINGW32__
#include <windows.h>
#define USE_NATIVE_EVENT 0

#if USE_NATIVE_EVENT
class ScreenSaverEventFilter
#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
        : public QAbstractNativeEventFilter
#endif
{
public:
    //screensaver is global
    static ScreenSaverEventFilter& instance() {
        static ScreenSaverEventFilter sSSEF;
        return sSSEF;
    }
    void enable(bool yes = true) {
        if (!yes) {
#if QT_VERSION < QT_VERSION_CHECK(5, 0, 0)
            mLastEventFilter = QAbstractEventDispatcher::instance()->setEventFilter(eventFilter);
#else
            QAbstractEventDispatcher::instance()->installNativeEventFilter(this);
#endif
        } else {
            if (!QAbstractEventDispatcher::instance())
                return;
#if QT_VERSION < QT_VERSION_CHECK(5, 0, 0)
            mLastEventFilter = QAbstractEventDispatcher::instance()->setEventFilter(mLastEventFilter);
#else
            QAbstractEventDispatcher::instance()->removeNativeEventFilter(this);
#endif
        }
    }
    void disable(bool yes = true) {
        enable(!yes);
    }

    bool nativeEventFilter(const QByteArray &eventType, void *message, long *result) {
        Q_UNUSED(eventType);
        MSG* msg = static_cast<MSG*>(message);
        //qDebug("ScreenSaverEventFilter: %p", msg->message);
        if (WM_DEVICECHANGE == msg->message) {
            qDebug("~~~~~~~~~~device event");
            /*if (msg->wParam == DBT_DEVICEREMOVECOMPLETE) {
                qDebug("Remove device");
            }*/

        }
        if (msg->message == WM_SYSCOMMAND
                && ((msg->wParam & 0xFFF0) == SC_SCREENSAVE
                    || (msg->wParam & 0xFFF0) == SC_MONITORPOWER)
        ) {
            //qDebug("WM_SYSCOMMAND SC_SCREENSAVE SC_MONITORPOWER");
            if (result) {
                //*result = 0; //why crash?
            }
            return true;
        }
        return false;
    }
private:
    ScreenSaverEventFilter() {}
    ~ScreenSaverEventFilter() {}
#if QT_VERSION < QT_VERSION_CHECK(5, 0, 0)
    static QAbstractEventDispatcher::EventFilter mLastEventFilter;
    static bool eventFilter(void* message) {
        return ScreenSaverEventFilter::instance().nativeEventFilter("windows_MSG", message, 0);
    }
#endif
};
#if QT_VERSION < QT_VERSION_CHECK(5, 0, 0)
QAbstractEventDispatcher::EventFilter ScreenSaverEventFilter::mLastEventFilter = 0;
#endif
#endif //USE_NATIVE_EVENT
#endif //Q_OS_WIN


ScreenSaver& ScreenSaver::instance()
{
    static ScreenSaver sSS;
    return sSS;
}

ScreenSaver::ScreenSaver()
{
#ifdef Q_OS_LINUX
    cookieID = 0;
#endif //Q_OS_LINUX
}

//http://msdn.microsoft.com/en-us/library/windows/desktop/ms724947%28v=vs.85%29.aspx
//http://msdn.microsoft.com/en-us/library/windows/desktop/aa373208%28v=vs.85%29.aspx
/* TODO:
 * SystemParametersInfo will change system wild settings. An application level solution is better. Use native event
 * SPI_SETSCREENSAVETIMEOUT?
 * SPI_SETLOWPOWERTIMEOUT, SPI_SETPOWEROFFTIMEOUT for 32bit
 */
bool ScreenSaver::enable(bool yes)
{
    bool rv = false;
#if defined(Q_OS_WIN) && !defined(Q_OS_WINRT)
#if USE_NATIVE_EVENT
    ScreenSaverEventFilter::instance().enable(yes);
    rv = true;
    return true;
#else
    /*
        int val; //SPI_SETLOWPOWERTIMEOUT, SPI_SETPOWEROFFTIMEOUT. SPI_SETSCREENSAVETIMEOUT
        if ( SystemParametersInfo(SPI_GETSCREENSAVETIMEOUT, 0, &val, 0)) {
            SystemParametersInfo(SPI_SETSCREENSAVETIMEOUT, val, NULL, 0);
        }
     */
    //http://msdn.microsoft.com/en-us/library/aa373208%28VS.85%29.aspx
    static EXECUTION_STATE sLastState = 0;
    if (!yes) {
        //Calling SetThreadExecutionState without ES_CONTINUOUS simply resets the idle timer; to keep the display
        // or system in the working state, the thread must call SetThreadExecutionState periodically
        //ES_CONTINUOUS: Informs the system that the state being set should remain in effect until the next call
        // that uses ES_CONTINUOUS and one of the other state flags is cleared.
        sLastState = SetThreadExecutionState(ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED | ES_CONTINUOUS);
    } else {
        if (sLastState)
            sLastState = SetThreadExecutionState(sLastState|ES_CONTINUOUS);
    }
    rv = sLastState != 0;
#endif //USE_NATIVE_EVENT
#endif //defined(Q_OS_WIN) && !defined(Q_OS_WINRT)
#ifdef Q_OS_LINUX
    if (yes) {
        if (cookieID) {
            screenSaverInterface.call("UnInhibit", cookieID);
            rv = true;
            qDebug("ScreenSaver:: UnInhibit Successful %d", cookieID);
        } else {
            qWarning("ScreenSaver::Asked for Dbus UnInhibit, but Inhibit never called. Ignoring");
        }
    } else {
        if(screenSaverInterface.isValid()) {
            QDBusReply<uint> reply = screenSaverInterface.call(
                "Inhibit", "stremio", "video");
            if (reply.isValid()) {
                cookieID = reply.value();
                rv = true;
                qDebug("ScreenSaver::Dbus Inhibit Successful %d", cookieID);
            } else {   
                qWarning("ScreenSaver::Dbus Inhibit Failed");
            }
        }
    }
#endif //Q_OS_LINUX
#if defined(Q_OS_MAC) && !defined(Q_OS_IOS)
    // kIOPMAssertionTypeNoDisplaySleep prevents display sleep,
    // kIOPMAssertionTypeNoIdleSleep prevents idle sleep

    // reasonForActivity is a descriptive string used by the system whenever it needs
    // to tell the user why the system is not sleeping.
    IOReturn success;
    if (!yes) {
        CFStringRef reasonForActivity = CFSTR("Disable Screensaver");
        success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn,
                                              reasonForActivity, &assertionID);
    } else {
        success = IOPMAssertionRelease(assertionID);
        rv = true;
    }

    rv = success == kIOReturnSuccess;
#endif //Q_OS_MAC
    if (!rv) {
        qWarning("Failed to enable/disable screen saver (enabled: %d)", yes);
    } else {
        qDebug("Successful to enable/disable screen saver (enabled: %d)", yes);
    }
    return rv;
}

void ScreenSaver::enable()
{
    enable(true);
}

void ScreenSaver::disable()
{
    enable(false);
}
