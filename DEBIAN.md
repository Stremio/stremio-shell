# Build Stremio for Debian GNU/Linux

These instructions have been tested in Debian Buster (Testing)

## 1. Start by cloning the GIT repository:

``git clone --recurse-submodules -j8 git://github.com/Stremio/stremio-shell.git``

## 2. Install QTCreator

``sudo apt-get install qtcreator qt5-qmake qt5-default g++ pkgconf libssl-dev``

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

``sudo apt-get install qml-module-qtwebchannel qml-module-qt-labs-platform qml-module-qtwebengine qml-module-qtquick-dialogs qml-module-qtquick-controls qtdeclarative5-dev``

Now you should be able to run it normally.

## 7. Run Stremio

``./build/stremio``

If you get a popup window stating:

Error while starting streaming server. Please consider re-installing Stremio from https://www.stremio.com

Perhaps you've skipped step #5

Cheers!
