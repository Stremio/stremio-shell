## Build

### Build instructions for Mac OS X

1. Make sure you have Qt 5.10.x or newer and Qt Creator
2. Open the project in Qt creator
3. build it
4. do ``cp -R /Applications/Stremio.app/Contents/Resources/WCjs/lib/ build-stremio-Desktop_Qt_5_7_0_clang_64bit-Debug/stremio.app/Contents/MacOS/lib``

#### Command line to build:

```
qmake
make
```

### Build instructions for Debian GNU/Linux

Please, refer to [DEBIAN.md](https://github.com/Stremio/stremio-shell/blob/master/DEBIAN.md) for a detailed explanation of how to build the latest Stremio in Debian.

## Releasing a version

1. Bump the version in the `stremio.pro` file
2. Create a git tag with the corresponding version

## Arguments

``--development``: would make the shell load from `http://127.0.0.1:11470` instead of `https://app.strem.io` and would force the shell to not try and start a streaming server

``--staging``: would load the web UI from `https://staging.strem.io`

``--webui-url=``: allows defining a different web UI URL

``--streaming-server``: when used with ``development``, it would make the shell try to start a streaming server; this is the default behaviour in production

``--autoupdater-force``: would force the auto-updater to check for a new version

``--autoupdater-force-full``: would force the auto-updater to always perform a full update (rather than partial)

``--autoupdater-endpoint=``: would override the default checking endpoints for the autoupdater
