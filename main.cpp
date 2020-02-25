#include <QQmlApplicationEngine>
#include <QtWebEngine>
#include <QSysInfo>

#include <clocale>

#define APP_TITLE "Stremio - All You Can Watch"

#define DESKTOP true

#ifdef DESKTOP
#include <QtWidgets/QApplication>
typedef QApplication Application;

#include <QQmlEngine>

#include <QStandardPaths>

#include <QSystemTrayIcon>
#include "systemtray.h"

#include "mainapplication.h"
#include "stremioprocess.h"
#include "mpv.h"
#include "screensaver.h"
#include "razerchroma.h"
#include "qclipboardproxy.h"

#else
#include <QGuiApplication>
#endif

void InitializeParameters(QQmlApplicationEngine& engine, MainApp& app) {
    QQmlContext *ctx = engine.rootContext();

    ctx->setContextProperty("applicationDirPath", QGuiApplication::applicationDirPath());
    ctx->setContextProperty("appTitle", QString(APP_TITLE));
    ctx->setContextProperty("autoUpdater", app.autoupdater);

    #ifdef QT_DEBUG
        ctx->setContextProperty("debug", true);
    #else
        ctx->setContextProperty("debug", false);
    #endif
}

int main(int argc, char **argv)
{
    #ifdef _WIN32
    // Default to ANGLE (DirectX), because that seems to eliminate so many issues on Windows
    // Also, according to the docs here: https://wiki.qt.io/Qt_5_on_Windows_ANGLE_and_OpenGL, ANGLE is also preferrable
    // We do not need advanced OpenGL features but we need more universal support

    Application::setAttribute(Qt::AA_UseOpenGLES);
    auto winVer = QSysInfo::windowsVersion();
    if(winVer <= QSysInfo::WV_WINDOWS7 && winVer != QSysInfo::WV_None) {
        qputenv("QT_ANGLE_PLATFORM", "d3d9");
    }
    #endif

    // This is really broken on Linux
    #ifndef Q_OS_LINUX
    Application::setAttribute(Qt::AA_EnableHighDpiScaling);
    #endif

    Application::setApplicationName("Stremio");
    Application::setApplicationVersion(STREMIO_SHELL_VERSION);
    Application::setOrganizationName("Smart Code ltd");
    Application::setOrganizationDomain("stremio.com");

    MainApp app(argc, argv, true);
    #ifndef Q_OS_MACOS
    if( app.isSecondary() ) {
        if( app.arguments().count() > 1)
            app.sendMessage( app.arguments().at(1).toUtf8() );
        else
            app.sendMessage( "SHOW" );
        //app.sendMessage( app.arguments().join(' ').toUtf8() );
        return 0;
    }
    #endif

    app.setWindowIcon(QIcon(":/images/stremio_window.png"));


    // Qt sets the locale in the QGuiApplication constructor, but libmpv
    // requires the LC_NUMERIC category to be set to "C", so change it back.
    std::setlocale(LC_NUMERIC, "C");
    
    qmlRegisterType<Process>("com.stremio.process", 1, 0, "Process");
    qmlRegisterType<ScreenSaver>("com.stremio.screensaver", 1, 0, "ScreenSaver");
    qmlRegisterType<MpvObject>("com.stremio.libmpv", 1, 0, "MpvObject");
    qmlRegisterType<RazerChroma>("com.stremio.razerchroma", 1, 0, "RazerChroma");
    qmlRegisterType<ClipboardProxy>("com.stremio.clipboard", 1, 0, "Clipboard");

    QQmlApplicationEngine engine;
    InitializeParameters(engine, app);
    QtWebEngine::initialize();
 
    SystemTray * systemTray = new SystemTray();
    QQmlContext * context = engine.rootContext();
    // Set access to an object of class properties in QML context
    context->setContextProperty("systemTray", systemTray);
 

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    #ifndef Q_OS_MACOS
    QObject::connect( &app, &SingleApplication::receivedMessage, &app, &MainApp::processMessage );
    #endif
    QObject::connect( &app, SIGNAL(receivedMessage(QVariant, QVariant)), engine.rootObjects().value(0),
                      SLOT(onAppMessageReceived(QVariant, QVariant)) );

    return app.exec();
}
