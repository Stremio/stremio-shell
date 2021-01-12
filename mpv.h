#ifndef MPVRENDERER_H_
#define MPVRENDERER_H_
#define MPV_ENABLE_DEPRECATED 0

#include <QtQuick/QQuickFramebufferObject>

#include <mpv/client.h>
#include <mpv/render_gl.h>
#include <mpv/qthelper.hpp>

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT

    mpv_handle *mpv;
    mpv_render_context *mpv_gl;

    friend class MpvRenderer;

public:
    static void on_update(void *ctx);

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
    static void wakeup(void *ctx);
    void handle_mpv_event(mpv_event *event);
    void initialize_mpv();
    QSet<QString> observed_properties;
};

#endif
