# Build Stremio for Debian GNU/Linux

These instructions have been tested in Debian Buster (Testing)

## 1. Start by cloning the GIT repository:

``git clone --recurse-submodules -j8 https://github.com/Stremio/stremio-shell.git``

## 2. Install QtCreator

``sudo apt-get install qtcreator qt5-qmake qt5-default g++ pkgconf libssl-dev``

## 3. Generate the Makefiles for Stremio

``cd stremio-shell``

``qmake``

## 3.1 Install missing dependencies

To directly install all dependencies, run:

``sudo apt-get install libmpv-dev libqt5webview5-dev libkf5webengineviewer-dev qml-module-qtwebchannel qml-module-qt-labs-platform qml-module-qtwebengine qml-module-qtquick-dialogs qml-module-qtquick-controls qtdeclarative5-dev qml-module-qt-labs-settings qml-module-qt-labs-folderlistmodel cmake librsvg2-bin ``

## 4. Compile Stremio:

`make -f release.makefile`

This will create a new directory named `build` where the `stremio` binary will be located. It will also generate icons and download the streaming server.


## 5. Prepare the streaming server

Upon running the ./build/stremio binary, stremio should start up as usual. Except it won't start the streaming server, for this, you need to have NodeJS installed and server.js in your working dir, for which you need to do:

``cp ./server.js ./build/ && ln -s "$(which node)" ./build/node``

## 6. Run Stremio

``./build/stremio``

If you get a popup window stating:

`Error while starting streaming server. Please consider re-installing Stremio from https://www.stremio.com`

Perhaps you've skipped step #5

Cheers!
