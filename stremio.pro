TEMPLATE = app

VERSION=4.4.137

DEFINES += STREMIO_SHELL_VERSION=\\\"$$VERSION\\\"

ICON = images/stremio.icns

QMAKE_TARGET_BUNDLE_PREFIX = com.smartcodeltd

QMAKE_INFO_PLIST = Info.plist

QT += qml quick network
CONFIG += c++11

include(deps/singleapplication/singleapplication.pri)
DEFINES += QAPPLICATION_CLASS=QApplication

mac {
    QMAKE_LFLAGS_SONAME  = -Wl,-install_name,@executable_path/../Frameworks/
    LIBS += -framework CoreFoundation
    QMAKE_RPATHDIR += @executable_path/../Frameworks
    QMAKE_RPATHDIR += @executable_path/lib
    #LIBS += -L $$PWD/deps/libmpv/mac/lib -lmpv
    LIBS += -L${MPV_BIN_PATH}/lib -lmpv -lc
}

# pkg-config way of linking with mpv works perfectly on the mac distribution process, because macdeployqt will also ship all libraries
# however, we want to hardcode specific *.dylibs, because (1) includes are hardcoded, (2) installing mpv with brew is slow 
unix:!mac {
    QMAKE_RPATHDIR += '$ORIGIN'
    QT_CONFIG -= no-pkg-config
    CONFIG += link_pkgconfig
    LIBS += -L$$PWD/../mpv-build/mpv/build -lmpv
}

win32 {
    RC_ICONS = $$PWD/images/stremio.ico
    LIBS += $$PWD/deps/libmpv/win32/mpv.lib
}

INCLUDEPATH += deps/libmpv/include

# OpenSSL
unix:!mac {
    LIBS += -lcrypto
}
mac {
    LIBS += -L${OPENSSL_BIN_PATH}/lib -lcrypto
    INCLUDEPATH += ${OPENSSL_BIN_PATH}/include
}
win32{
    # First one is the convention for builds at slproweb.com, the other at www.npcglib.org (used by AppVeyor)
    LIBS += C:/OpenSSL-Win32/lib/libcrypto.lib
    INCLUDEPATH += C:/OpenSSL-Win32/include
}

# Razer Chroma SDK
win32 {
    include(deps/chroma/chroma.pri)
}

QT += widgets

# TODO: if def WEBENGINE
QT += webengine webchannel dbus
WEBENGINE_CONFIG+=use_proprietary_codecs

SOURCES += main.cpp \
    mpv.cpp \
    stremioprocess.cpp \
    screensaver.cpp \
    autoupdater.cpp \
    systemtray.cpp \
    razerchroma.cpp \
    qclipboardproxy.cpp \
    verifysig.c

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    mpv.h \
    stremioprocess.h \
    screensaver.h \
    mainapplication.h \
    autoupdater.h \
    systemtray.h \
    razerchroma.h \
    qclipboardproxy.h \
    verifysig.h \
    publickey.h
