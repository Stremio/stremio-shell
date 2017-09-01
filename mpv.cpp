#include "mpv.h"

#include <stdexcept>
#include <clocale>

#include <QObject>
#include <QJsonObject>

#include <QtGlobal>
#include <QOpenGLContext>

#include <QtGui/QOpenGLFramebufferObject>

#include <QtQuick/QQuickWindow>
#include <QtQuick/QQuickView>

#if defined(Q_OS_WIN32)
#include <windows.h>
#include <dwmapi.h>
#pragma comment (lib, "dwmapi.lib")
#endif

class MpvRenderer : public QQuickFramebufferObject::Renderer
{
    static void *get_proc_address(void *ctx, const char *name) {
        (void)ctx;
        QOpenGLContext *glctx = QOpenGLContext::currentContext();
        if (!glctx)
            return NULL;
        return (void *)glctx->getProcAddress(QByteArray(name));
    }

    mpv::qt::Handle mpv;
    QQuickWindow *window;
    mpv_opengl_cb_context *mpv_gl;
public:
    MpvRenderer(const MpvObject *obj)
        : mpv(obj->mpv), window(obj->window()), mpv_gl(obj->mpv_gl)
    {
        // Qt sets the locale in the QGuiApplication constructor, but libmpv
        // requires the LC_NUMERIC category to be set to "C", so change it back.
        std::setlocale(LC_NUMERIC, "C");
        
        int r = mpv_opengl_cb_init_gl(mpv_gl, NULL, get_proc_address, NULL);
        if (r < 0)
            throw std::runtime_error("could not initialize OpenGL");
    }

    virtual ~MpvRenderer()
    {
        // Until this call is done, we need to make sure the player remains
        // alive. This is done implicitly with the mpv::qt::Handle instance
        // in this class.
        mpv_opengl_cb_uninit_gl(mpv_gl);
    }

    void render()
    {
        QOpenGLFramebufferObject *fbo = framebufferObject();
        window->resetOpenGLState();
        mpv_opengl_cb_draw(mpv_gl, fbo->handle(), fbo->width(), fbo->height());
        window->resetOpenGLState();
    }
};

MpvObject::MpvObject(QQuickItem * parent)
    : QQuickFramebufferObject(parent), mpv_gl(0)
{
#ifdef Q_OS_WIN32
  // Request Multimedia Class Schedule Service.
  DwmEnableMMCSS(TRUE);
#endif
    
    mpv = mpv::qt::Handle::FromRawHandle(mpv_create());
    if (!mpv)
        throw std::runtime_error("could not create mpv context");

    mpv_set_option_string(mpv, "terminal", "yes");
    mpv_set_option_string(mpv, "msg-level", "all=v");

    if (mpv_initialize(mpv) < 0)
        throw std::runtime_error("could not initialize mpv context");

    // Make use of the MPV_SUB_API_OPENGL_CB API.
    mpv::qt::set_property(mpv, "vo", "opengl-cb");

    // Enable opengl-hwdec-interop so we can set hwdec at runtime
    mpv::qt::set_property(mpv, "opengl-hwdec-interop", "auto");

    // No need to set, will be auto-detected
    //mpv::qt::set_property(mpv, "opengl-backend", "angle");

    // Set cache to a reasonable value
    mpv::qt::set_property(mpv, "cache-default", 15000);
    mpv::qt::set_property(mpv, "cache-backbuffer", 15000);
    mpv::qt::set_property(mpv, "cache-secs", 10);

    // Visible app / stream names
    mpv::qt::set_property(mpv, "audio-client-name", QCoreApplication::applicationName());
    mpv::qt::set_property(mpv, "title", QCoreApplication::applicationName());
 
    // Don't stop on audio output issues
    mpv::qt::set_property(mpv, "audio-fallback-to-null", "yes");

    // Setup the callback that will make QtQuick update and redraw if there
    // is a new video frame. Use a queued connection: this makes sure the
    // doUpdate() function is run on the GUI thread.
    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl)
        throw std::runtime_error("OpenGL not compiled in");
    mpv_opengl_cb_set_update_callback(mpv_gl, MpvObject::on_update, (void *)this);
    connect(this, &MpvObject::onUpdate, this, &MpvObject::doUpdate,
            Qt::QueuedConnection);

    // Setup handling events from MPV
    mpv_set_wakeup_callback(mpv, wakeup, this);
}

MpvObject::~MpvObject()
{
    if (mpv_gl)
        mpv_opengl_cb_set_update_callback(mpv_gl, NULL, NULL);
}

void MpvObject::on_update(void *ctx)
{
    MpvObject *self = (MpvObject *)ctx;
    emit self->onUpdate();
}

// connected to onUpdate(); signal makes sure it runs on the GUI thread
void MpvObject::doUpdate()
{
    update();
}

void MpvObject::command(const QVariant& params)
{
    // does mpv_command_node internally; maybe we should use async? However, it seems async is not really needed atm...
    mpv::qt::command(mpv, params);
}

void MpvObject::setProperty(const QString& name, const QVariant& value)
{
    mpv::qt::set_property_variant(mpv, name, value);
}

void MpvObject::observeProperty(const QString& name)
{
    // NOTE: it's possible to use MPV_FORMAT_NONE to only observe the event change, without caring about value
    mpv_observe_property(mpv, 0, name.toStdString().c_str(), MPV_FORMAT_NODE);
}

void MpvObject::wakeup(void *ctx)
{
    QMetaObject::invokeMethod((MpvObject*)ctx, "on_mpv_events", Qt::QueuedConnection);
}

void MpvObject::on_mpv_events()
{
    // Process all events, until the event queue is empty.
    while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) {
            break;
        }
        handle_mpv_event(event);
    }
}

void MpvObject::handle_mpv_event(mpv_event *event) {
    QJsonObject eventJson;

    eventJson["id"] = qint64(event->reply_userdata);

    if (event->error < 0)
        eventJson["error"] = QString(mpv_error_string(event->error));

    switch (event->event_id) {
        // WARNING: we are not handling the following event types, it does not seem we need them:
        // case MPV_EVENT_LOG_MESSAGE:
        // case MPV_EVENT_CLIENT_MESSAGE:
        case MPV_EVENT_PROPERTY_CHANGE: {
            mpv_event_property *prop = (mpv_event_property *) event->data;
            eventJson["name"] = QString(prop->name);

            // NOTE: because we always observe as node, we can handle only that case; we are handling the others, to be safe :)
            switch (prop->format) {
            case MPV_FORMAT_NODE:
                 eventJson["data"] = QJsonValue::fromVariant(mpv::qt::node_to_variant((mpv_node *) prop->data));
                 break;
            case MPV_FORMAT_DOUBLE:
                eventJson["data"] = *(double *)prop->data;
                break;
            case MPV_FORMAT_FLAG:
                eventJson["data"] = *(int *)prop->data;
                break;
            case MPV_FORMAT_STRING:
                eventJson["data"] = QString(*(char **)prop->data);
                break;
            default: 
                break;
            }

            Q_EMIT mpvEvent("mpv-prop-change", eventJson);
            break;
        }
        case MPV_EVENT_END_FILE: {
            Q_EMIT mpvEvent("mpv-event-ended", eventJson);
            break;
        }
        default: {
            break;
        }
    }
}

QVariant MpvObject::getProperty(const QString& name) {
    return mpv::qt::get_property(mpv, name);
}
QQuickFramebufferObject::Renderer *MpvObject::createRenderer() const
{
    window()->setPersistentOpenGLContext(true);
    window()->setPersistentSceneGraph(true);
    return new MpvRenderer(this);
}
