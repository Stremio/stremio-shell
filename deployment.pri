unix:!android {
    isEmpty(target.path) {
        qnx {
            target.path = $$PREFIX/tmp/$${TARGET}/bin
        } else {
            target.path = $$PREFIX/opt/$${TARGET}/bin
        }
        export(target.path)
    }
    INSTALLS += target
}

export(INSTALLS)
