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
### Build instructions for Windows

Please, refer to [WINDOWS.md](https://github.com/Stremio/stremio-shell/blob/master/WINDOWS.md) for a detailed explanation of how to build the latest Stremio in Windows.


### Build instructions for Debian GNU/Linux

Please, refer to [DEBIAN.md](https://github.com/Stremio/stremio-shell/blob/master/DEBIAN.md) for a detailed explanation of how to build the latest Stremio in Debian.

### Build instructions for OpenSuseLeap 15.0

Please, refer to [OpenSuseLeap.md](https://github.com/Stremio/stremio-shell/blob/master/OpenSuseLeap.md) for a detailed explanation of how to build the latest Stremio in OpenSuseLeap 15.0

### Build instructions for Docker builds of supported Linux distros

There are Docker files and setup scripts for supported Linux distributions (Debian, Fedora, Arch), located in the `./distros` directory.

There is also an automated build script located in `./dist-utils/build-package.sh`.

For more information refer to the [DOCKER.md](DOCKER.md) file.

## Third-party install scripts

There are repositories for third-party install scripts that may be useful for you, most notably: https://github.com/alexandru-balan/Stremio-Install-Scripts

We give no guarantees about their correctness or security.

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

To test the autoupdater, you can use a command like: `./stremio --autoupdater-force --autoupdater-endpoint="https://www.stremio.com/updater/check?force=true"`; `force=true` passed to the update endpoint would cause it to always return the latest descriptor
