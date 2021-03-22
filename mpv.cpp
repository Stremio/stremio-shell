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

namespace
{
void on_mpv_redraw(void *ctx)
{
    MpvObject::on_update(ctx);
}

static void *get_proc_address_mpv(void *ctx, const char *name)
{
    Q_UNUSED(ctx)

    QOpenGLContext *glctx = QOpenGLContext::currentContext();
    if (!glctx)
        return nullptr;

    return reinterpret_cast<void *>(glctx->getProcAddress(QByteArray(name)));
}

} // namespace


class MpvRenderer : public QQuickFramebufferObject::Renderer
{
    MpvObject *obj;

    public:
    MpvRenderer(MpvObject *new_obj)
        : obj{new_obj}
    {
        // Qt sets the locale in the QGuiApplication constructor, but libmpv
        // requires the LC_NUMERIC category to be set to "C", so change it back.
        std::setlocale(LC_NUMERIC, "C");
    }

    virtual ~MpvRenderer()
    {
    }

    // This function is called when a new FBO is needed.
    // This happens on the initial frame.
    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size)
    {
        // init mpv_gl:
        if (!obj->mpv_gl)
        {
            mpv_opengl_init_params gl_init_params{get_proc_address_mpv, nullptr, nullptr};
            mpv_render_param params[]{
                {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
                {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
                {MPV_RENDER_PARAM_INVALID, nullptr}};

            if (mpv_render_context_create(&obj->mpv_gl, obj->mpv, params) < 0)
                throw std::runtime_error("failed to initialize mpv GL context");
            mpv_render_context_set_update_callback(obj->mpv_gl, on_mpv_redraw, obj);
        }

        return QQuickFramebufferObject::Renderer::createFramebufferObject(size);
    }

    void render()
    {
        obj->window()->resetOpenGLState();

        QOpenGLFramebufferObject *fbo = framebufferObject();
        mpv_opengl_fbo mpfbo{static_cast<int>(fbo->handle()), fbo->width(), fbo->height(), 0};
        int flip_y{0};

        mpv_render_param params[] = {
            // Specify the default framebuffer (0) as target. This will
            // render onto the entire screen. If you want to show the video
            // in a smaller rectangle or apply fancy transformations, you'll
            // need to render into a separate FBO and draw it manually.
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpfbo},
            // Flip rendering (needed due to flipped GL coordinate system).
            {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
            {MPV_RENDER_PARAM_INVALID, nullptr}};
        // See render_gl.h on what OpenGL environment mpv expects, and
        // other API details.
        mpv_render_context_render(obj->mpv_gl, params);

        obj->window()->resetOpenGLState();
     }
};

MpvObject::MpvObject(QQuickItem * parent)
    : QQuickFramebufferObject(parent), mpv{mpv_create()}, mpv_gl(nullptr)
{
#ifdef Q_OS_WIN32
  // Request Multimedia Class Schedule Service.
  DwmEnableMMCSS(TRUE);
#endif
    
    if (!mpv)
        throw std::runtime_error("could not create mpv context");

    // Setup the callback that will make QtQuick update and redraw if there
    // is a new video frame. Use a queued connection: this makes sure the
    // doUpdate() function is run on the GUI thread.
    connect(this, &MpvObject::onUpdate, this, &MpvObject::doUpdate,
            Qt::QueuedConnection);

    initialize_mpv();

    // The player is hidden by default. It is shown only whe a video stream is available
    this->setVisible(false);
    this->observeProperty("vid");
}

MpvObject::~MpvObject()
{
    if (mpv_gl) // only initialized if something got drawn
    {
        mpv_render_context_free(mpv_gl);
    }

    mpv_terminate_destroy(mpv);
}

void MpvObject::initialize_mpv() {
    // terminal=yes brings us all the terminal logs; on windows it's much better with winpty (https://github.com/mpv-player/mpv/blob/master/DOCS/compile-windows.md)
    mpv_set_option_string(mpv, "terminal", "yes");
    mpv_set_option_string(mpv, "msg-level", "all=v");

    if (mpv_initialize(mpv) < 0)
        throw std::runtime_error("could not initialize mpv context");

    // Make use of the MPV_SUB_API_OPENGL_CB API.
    mpv::qt::set_property(mpv, "vo", "libmpv");

    // Enable opengl-hwdec-interop so we can set hwdec at runtime
    mpv::qt::set_property(mpv, "gpu-hwdec-interop", "auto");

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

    // User-visible application name used by some audio APIs (at least PulseAudio).
    mpv::qt::set_property(mpv, "audio-client-name", QCoreApplication::applicationName());
    // User-visible stream title used by some audio APIs (at least PulseAudio and wasapi).
    mpv::qt::set_property(mpv, "title", QCoreApplication::applicationName());

    // // Setup handling events from MPV
    mpv_set_wakeup_callback(mpv, wakeup, this);

    foreach (const QString &name, observed_properties) {
        mpv_observe_property(mpv, 0, name.toStdString().c_str(), MPV_FORMAT_NODE);
    }
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
    mpv::qt::set_property(mpv, name, value);
}

void MpvObject::observeProperty(const QString& name)
{
    observed_properties.insert(name);
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
                // Show the player only if there is a video stream
                if(((mpv_node *)prop->data)->format == MPV_FORMAT_INT64 && eventJson["name"] == "vid")
                    this->setVisible(true);
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
            // Hide player back when playback is finished
            this->setVisible(false);
            mpv_event_end_file *endFile = (mpv_event_end_file *)event->data;
            switch (endFile->reason) {
                case MPV_END_FILE_REASON_ERROR:
                    eventJson["reason"] = "error";
                    eventJson["error"] = mpv_error_string(endFile->error);
                    break;
                case MPV_END_FILE_REASON_QUIT:
                    eventJson["reason"] = "quit";
                    break;
                default:
                    eventJson["reason"] = "other";
                    break;
            }
            Q_EMIT mpvEvent("mpv-event-ended", eventJson);
            break;
        }
        case MPV_EVENT_SHUTDOWN: {
            if (mpv_gl) // only initialized if something got drawn
            {
                mpv_render_context_free(mpv_gl);
                mpv_gl = nullptr;
            }
            mpv_terminate_destroy(mpv);
            mpv = mpv_create();
            initialize_mpv();
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
    return new MpvRenderer(const_cast<MpvObject *>(this));
}
