    #ifndef SYSTEMTRAY_H
    #define SYSTEMTRAY_H
     
    #include <QObject>
    #include <QAction>
    #include <QSystemTrayIcon>
     
    class SystemTray : public QObject
    {
        Q_OBJECT
    public:
        explicit SystemTray(QObject *parent = 0);
     
    signals:
        void signalIconMenuAboutToShow();
        void signalIconActivated();
        void signalShow();
        void signalAlwaysOnTop();
        void signalQuit();
     
    private slots:
        /* The slot that will accept the signal from the event click on the application icon in the system tray
         */
        void iconActivated(QSystemTrayIcon::ActivationReason reason);
     
    public slots:
        void hideIconTray();
        void updateVisibleAction(bool isVisible);
        void updateIsOnTop(bool isOnTop);
	void alwaysOnTopEnabled(bool enabled);
     
    private:
        /* Declare the object of future applications for the tray icon*/
        QSystemTrayIcon         * trayIcon;
        QAction * viewWindowAction;
        QAction * alwaysOnTopAction;
    };
     
    #endif // SYSTEMTRAY_H
