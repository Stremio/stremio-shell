#include "mpv.h"

#include <QJsonObject>
#include <QOpenGLContext>
#include <QtQuick/QQuickWindow>
#include <QtGui/QOpenGLFramebufferObject>

#if defined(Q_OS_WIN32)
#include <windows.h>
#include <dwmapi.h>
#pragma comment (lib, "dwmapi.lib")
#endif

class MpvRenderer : public QQuickFramebufferObject::Renderer
{
public:
    MpvRenderer(MpvVideo *video)
        : video{video}
    {
        if (mpv_opengl_cb_init_gl(video->mpv_gl, nullptr, MpvRenderer::get_proc_address, nullptr) < 0)
            throw std::runtime_error("could not initialize OpenGL");
    }

    virtual ~MpvRenderer()
    {
        mpv_opengl_cb_uninit_gl(video->mpv_gl);
    }

    virtual void render()
    {
        video->window()->resetOpenGLState();
        QOpenGLFramebufferObject *fbo = framebufferObject();
        mpv_opengl_cb_draw(video->mpv_gl, static_cast<int>(fbo->handle()), fbo->width(), fbo->height());
        video->window()->resetOpenGLState();
    }

    static void *get_proc_address(void *ctx, const char *name)
    {
        Q_UNUSED(ctx);
        QOpenGLContext *glctx = QOpenGLContext::currentContext();
        if (!glctx)
            return nullptr;
        return reinterpret_cast<void*>(glctx->getProcAddress(QByteArray(name)));
    }
private:
    MpvVideo *video;
};

MpvVideo::MpvVideo(QQuickItem * parent)
    : QQuickFramebufferObject(parent), mpv_gl(nullptr)
{
#ifdef Q_OS_WIN32
    DwmEnableMMCSS(TRUE);
#endif

    mpv = mpv::qt::Handle::FromRawHandle(mpv_create());
    if (!mpv)
        throw std::runtime_error("could not create mpv context");

    if (mpv_initialize(mpv) < 0)
        throw std::runtime_error("could not initialize mpv context");

    mpv_gl = reinterpret_cast<mpv_opengl_cb_context*>(mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB));
    if (!mpv_gl)
        throw std::runtime_error("OpenGL not compiled in");

    mpv_opengl_cb_set_update_callback(mpv_gl, MpvVideo::onUpdate, reinterpret_cast<void*>(this));
    mpv_set_wakeup_callback(mpv, MpvVideo::wakeup, this);
}

MpvVideo::~MpvVideo()
{
    if (mpv_gl)
        mpv_opengl_cb_set_update_callback(mpv_gl, nullptr, nullptr);
}

QQuickFramebufferObject::Renderer *MpvVideo::createRenderer() const
{
    window()->setPersistentOpenGLContext(true);
    window()->setPersistentSceneGraph(true);
    return new MpvRenderer(const_cast<MpvVideo*>(this));
}

void MpvVideo::setOption(const QString& name, const QVariant& value)
{
    mpv::qt::set_option_variant(mpv, name, value);
}

void MpvVideo::observeProperty(const QString& name)
{
    mpv_observe_property(mpv, 0, name.toStdString().c_str(), MPV_FORMAT_NODE);
}

void MpvVideo::unobserveAllProperties()
{
    mpv_unobserve_property(mpv, 0);
}

QVariant MpvVideo::getProperty(const QString& name)
{
    QVariant value = mpv::qt::get_property(mpv, name);
    if (mpv::qt::is_error(value)) {
        return QVariant::fromValue(nullptr);
    }

    return value;
}

void MpvVideo::setProperty(const QString& name, const QVariant& value)
{
    mpv::qt::set_property(mpv, name, value);
}

void MpvVideo::command(const QVariant& args)
{
    mpv::qt::command(mpv, args);
}

void MpvVideo::processEvents()
{
    while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) {
            break;
        }

        QJsonObject eventData;
        if (event->error < 0) {
            eventData["code"] = event->error;
            eventData["message"] = QString(mpv_error_string(event->error));
            Q_EMIT mpvEvent("error", eventData);
            continue;
        }

        switch (event->event_id) {
            case MPV_EVENT_PROPERTY_CHANGE: {
                mpv_event_property *prop = reinterpret_cast<mpv_event_property*>(event->data);
                eventData["propName"] = QString(prop->name);
                switch (prop->format) {
                    case MPV_FORMAT_NODE: {
                        eventData["propValue"] = QJsonValue::fromVariant(mpv::qt::node_to_variant(reinterpret_cast<mpv_node*>(prop->data)));
                        break;
                    }
                    case MPV_FORMAT_DOUBLE: {
                        eventData["propValue"] = *reinterpret_cast<double*>(prop->data);
                        break;
                    }
                    case MPV_FORMAT_FLAG: {
                        eventData["propValue"] = *reinterpret_cast<int*>(prop->data);
                        break;
                    }
                    case MPV_FORMAT_STRING: {
                        eventData["propValue"] = QString(*reinterpret_cast<char**>(prop->data));
                        break;
                    }
                    default: {
                        break;
                    }
                }

                Q_EMIT mpvEvent("propChanged", eventData);
                break;
            }
            case MPV_EVENT_END_FILE: {
                mpv_event_end_file *end = reinterpret_cast<mpv_event_end_file*>(event->data);
                if (end->reason == MPV_END_FILE_REASON_ERROR) {
                    eventData["code"] = end->error;
                    eventData["message"] = QString(mpv_error_string(end->error));
                    Q_EMIT mpvEvent("error", eventData);
                } else {
                    Q_EMIT mpvEvent("ended");
                }

                break;
            }
            default: {
                break;
            }
        }
    }
}

void MpvVideo::wakeup(void *ctx)
{
    QMetaObject::invokeMethod(reinterpret_cast<MpvVideo*>(ctx), "processEvents", Qt::QueuedConnection);
}

void MpvVideo::onUpdate(void *ctx)
{
    QMetaObject::invokeMethod(reinterpret_cast<MpvVideo*>(ctx), "update", Qt::QueuedConnection);
}
