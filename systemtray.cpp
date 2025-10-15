    #include "systemtray.h"
    #include <QMenu>
    #include <QSystemTrayIcon>
    #include <QOperatingSystemVersion>
    SystemTray::SystemTray(QObject *parent) : QObject(parent)
    {
     
        // Create a context menu with two items
        QMenu *trayIconMenu = new QMenu();


        viewWindowAction = new QAction(tr("Show window"), this);
        viewWindowAction->setCheckable(true);

        alwaysOnTopAction = new QAction(tr("Always on top"), this);
        alwaysOnTopAction->setCheckable(true);
        
        QAction * quitAction = new QAction(tr("Quit"), this);

        /* to connect the signals clicks on menu items to the appropriate signals for QML.
         * */
        connect(trayIconMenu, &QMenu::aboutToShow, this, &SystemTray::signalIconMenuAboutToShow);
        connect(viewWindowAction, &QAction::triggered, this, &SystemTray::signalShow);
        connect(alwaysOnTopAction, &QAction::triggered, this, &SystemTray::signalAlwaysOnTop);
        connect(quitAction, &QAction::triggered, this, &SystemTray::signalQuit);
     
        trayIconMenu->addAction(viewWindowAction);
        trayIconMenu->addAction(alwaysOnTopAction);
        trayIconMenu->addAction(quitAction);


        /* Initialize the tray icon, icon set, and specify the tooltip
         * */
        trayIcon = new QSystemTrayIcon();
        trayIcon->setContextMenu(trayIconMenu);

        QIcon icon;

        if(QOperatingSystemVersion::current() <= QOperatingSystemVersion::Windows7) {
            icon = QIcon(":/images/stremio_window.png");
        } else {
            icon = QIcon::fromTheme("smartcode-stremio-tray", QIcon(":/images/stremio_window.png"));
            icon.setIsMask(true);
        }

        trayIcon->setIcon(icon);
        trayIcon->show();
     
        /* Also connect clicking on the icon to the signal handler of the pressing
         * */
        connect(trayIcon, SIGNAL(activated(QSystemTrayIcon::ActivationReason)),
                this, SLOT(iconActivated(QSystemTrayIcon::ActivationReason)));
    }

    /* The method that handles click on the application icon in the system tray
     * */
    void SystemTray::iconActivated(QSystemTrayIcon::ActivationReason reason)
    {
        switch (reason){
        case QSystemTrayIcon::Trigger:
            // In the case of pressing the signal on the icon tray in the call signal QML layer
#ifndef Q_OS_OSX
            emit signalIconActivated();
#endif
            break;
        default:
            break;
        }
    }
     
    void SystemTray::hideIconTray()
    {
        trayIcon->hide();
    }

    void SystemTray::updateVisibleAction(bool isVisible)
    {
        viewWindowAction->setChecked(isVisible);
    }

    void SystemTray::updateIsOnTop(bool isOnTop)
    {
        alwaysOnTopAction->setChecked(isOnTop);
    }

    void SystemTray::alwaysOnTopEnabled(bool enabled)
    {
        alwaysOnTopAction->setEnabled(enabled);
    }
