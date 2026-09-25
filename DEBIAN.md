# Build Stremio for Debian GNU/Linux

These instructions have been tested in Debian Bookworm 12 (Stable)

## Prebuilt packages

You may not need to build anything.

Stremio is now in Debian: `stremio` was accepted into unstable (main) on
24 September 2026, along with `stremio-server-installer` in contrib for the
streaming server component ([ITP #943703](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=943703),
[tracker](https://tracker.debian.org/pkg/stremio)).

```bash
sudo apt install stremio stremio-server-installer
```

That package builds [stremio-linux-shell](https://github.com/Stremio/stremio-linux-shell),
the GTK4 / WebKitGTK 6 client, rather than this Qt5 shell.

Prebuilt packages of **this** Qt5 shell, and builds for Debian stable, are
available from a third-party repository at https://debian.vejeta.com as
`stremio-qt5`.

The instructions below remain the way to build this repository from source.

## 1. Start by cloning the GIT repository:

``git clone --recurse-submodules -j8 https://github.com/Stremio/stremio-shell.git``

## 2. Install QTCreator and other dependencies

``sudo apt-get install qtcreator qt5-qmake g++ pkgconf libssl-dev librsvg2-bin``

## 3. Generate the Makefiles for Stremio

``cd stremio-shell``

``qmake``

## 3.1 Install missing dependencies

If you see this message:

```
Info: creating stash file /home/mendezr/development/misc/stremio-shell/.qmake.stash
Project ERROR: mpv development package not found
```

Then you need to install the development package for mpv (movie player)

``sudo apt-get install libmpv-dev``

If you see this message:

```
Project ERROR: Unknown module(s) in QT: qml quick webengine
```

Then install:
``sudo apt-get install libqt5webview5-dev``

If you find:
```Project ERROR: Unknown module(s) in QT: webengine```

Then install:

``sudo apt-get install libkf5webengineviewer-dev``

## 4. Compile Stremio:

$ make -f release.makefile

This will create a new directory named `build` where the `stremio' binary will be located. It will also generate icons and download the streaming server.


## 5. Prepare the streaming server

Upon running the ./build/stremio binary, stremio should start up as usual. Except it won't start the streaming server, for this you need to have NodeJS installed and server.js in your working dir, for which you need to do:

``cp ./server.js ./build/ && ln -s "$(which node)" ./build/node``


## 6. Install other dependencies

If you get this messages:

```
$ ./stremio
QQmlApplicationEngine failed to load component
qrc:/main.qml:3 module "QtWebChannel" is not installed
qrc:/main.qml:2 module "QtWebEngine" is not installed
qrc:/main.qml:12 module "Qt.labs.platform" is not installed
qrc:/main.qml:3 module "QtWebChannel" is not installed
qrc:/main.qml:2 module "QtWebEngine" is not installed
qrc:/main.qml:12 module "Qt.labs.platform" is not installed
qrc:/main.qml:3 module "QtWebChannel" is not installed
qrc:/main.qml:2 module "QtWebEngine" is not installed
qrc:/main.qml:12 module "Qt.labs.platform" is not installed
```

That means you need to install:

``sudo apt-get install qml-module-qtwebchannel qml-module-qt-labs-platform qml-module-qtwebengine qml-module-qtquick-dialogs qml-module-qtquick-controls qtdeclarative5-dev qml-module-qt-labs-settings qml-module-qt-labs-folderlistmodel``

Now you should be able to run it normally.

## 7. Run Stremio

``./build/stremio``

If you get a popup window stating:

Error while starting streaming server. Please consider re-installing Stremio from https://www.stremio.com

Perhaps you've skipped step #5

Cheers! 
