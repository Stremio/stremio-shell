#ifndef MPVRENDERER_H_
#define MPVRENDERER_H_

#include <QtQuick/QQuickFramebufferObject>
#include <mpv/opengl_cb.h>
#include <mpv/qthelper.hpp>

class MpvRenderer;

class MpvVideo : public QQuickFramebufferObject
{
    Q_OBJECT
    friend class MpvRenderer;
public:
    MpvVideo(QQuickItem *parent = nullptr);
    virtual ~MpvVideo();
    virtual Renderer *createRenderer() const;
public slots:
    void setOption(const QString& name, const QVariant& value);
    void observeProperty(const QString& name);
    void unobserveAllProperties();
    QVariant getProperty(const QString& name);
    void setProperty(const QString& name, const QVariant& value);
    void command(const QVariant& args);
signals:
    void mpvEvent(const QString& name, const QVariant& data = QVariant());
private:
    mpv::qt::Handle mpv;
    mpv_opengl_cb_context *mpv_gl;
    static void wakeup(void *ctx);
    static void onUpdate(void *ctx);
private slots:
    void processEvents();
};
#endif
