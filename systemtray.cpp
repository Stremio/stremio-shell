    #include "systemtray.h"
    #include <QMenu>
    #include <QSystemTrayIcon>
     
    SystemTray::SystemTray(QObject *parent) : QObject(parent)
    {
     
        // Create a context menu with two items
        QMenu *trayIconMenu = new QMenu();
     
        QAction * viewWindow = new QAction(trUtf8("Show/hide window"), this);
        QAction * quitAction = new QAction(trUtf8("Quit"), this);
     
        /* to connect the signals clicks on menu items to the appropriate signals for QML.
         * */
        connect(viewWindow, &QAction::triggered, this, &SystemTray::signalShow);
        connect(quitAction, &QAction::triggered, this, &SystemTray::signalQuit);
     
        trayIconMenu->addAction(viewWindow);
        trayIconMenu->addAction(quitAction);
     
        /* Initialize the tray icon, icon set, and specify the tooltip
         * */
        trayIcon = new QSystemTrayIcon();
        trayIcon->setContextMenu(trayIconMenu);
        QIcon icon = QIcon(":/images/stremio_tray_white.png");
        icon.setIsMask(true);
        trayIcon->setIcon(icon);
        trayIcon->show();
        trayIcon->setToolTip("Tray Program" "\n"
                             "Work with winimizing program to tray");
     
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
            emit signalIconActivated();
            break;
        default:
            break;
        }
    }
     
    void SystemTray::hideIconTray()
    {
        trayIcon->hide();
    }
