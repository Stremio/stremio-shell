unix:!android {
    isEmpty(target.path) {
        qnx {
            target.path = $$PREFIX/tmp/$${TARGET}/bin
        } else {
            target.path = $$PREFIX/opt/$${TARGET}
        }
        export(target.path)
    }
    static.files = smartcode-stremio.desktop
    static.path = $$target.path
    export(static.path)
    INSTALLS += static
    INSTALLS += target
}

export(INSTALLS)
