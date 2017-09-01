#ifndef MPVRENDERER_H_
#define MPVRENDERER_H_

#include <QtQuick/QQuickFramebufferObject>

#include <mpv/client.h>
#include <mpv/opengl_cb.h>
#include <mpv/qthelper.hpp>

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT

    mpv::qt::Handle mpv;
    mpv_opengl_cb_context *mpv_gl;

    friend class MpvRenderer;

public:
    MpvObject(QQuickItem * parent = 0);
    virtual ~MpvObject();
    virtual Renderer *createRenderer() const;
public slots:
    void command(const QVariant& params);
    void setProperty(const QString& name, const QVariant& value);
    QVariant getProperty(const QString& name);
    void observeProperty(const QString& name);
signals:
    void onUpdate();
    void mpvEvent(const QString& ev, const QVariant& value);
private slots:
    void doUpdate();
    void on_mpv_events();
private:
    static void on_update(void *ctx);
    static void wakeup(void *ctx);
    void handle_mpv_event(mpv_event *event);
};

#endif
