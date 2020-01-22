#include <QEvent>
#include <QFileOpenEvent>
#include "singleapplication.h"
#include "autoupdater.h"

#ifdef Q_OS_MACOS
#define APP_TYPE QApplication
#else
#define APP_TYPE SingleApplication
#endif

class MainApp : public APP_TYPE
{
    Q_OBJECT

  public: 
    MainApp(int &argc, char **argv, bool unique) : APP_TYPE(argc, argv, unique) {
      autoupdater = new AutoUpdater();
      autoupdater->moveToThread(&autoupdaterThread);
      autoupdaterThread.start();
    };
    ~MainApp() {
      delete autoupdater;
      autoupdaterThread.quit();
      autoupdaterThread.wait();
    };

    AutoUpdater* autoupdater;

    protected:
    bool event (QEvent *event) 
    {
      // The system requested us to open a file
      if (event->type() == QEvent::FileOpen)
      {
        QFileOpenEvent *openEvent = static_cast<QFileOpenEvent *>(event);
        emit this->receivedMessage(0, openEvent->url());
      }
      else
        return QApplication::event (event);

      return true;
    };

    public slots:
      void processMessage(quint32 instance, QByteArray msg) {
        emit this->receivedMessage(QVariant(instance), QVariant(QString(msg)));
      }

    signals:
      void receivedMessage(QVariant instanceID, QVariant message);
    
    private:
      QThread autoupdaterThread;
};
