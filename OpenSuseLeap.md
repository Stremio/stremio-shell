# Build Stremio for OpenSuseLeap15

These instructions have been tested in OpenSuseLeap15

## 1. Start by cloning the GIT repository:

``git clone --recurse-submodules -j8 git://github.com/Stremio/stremio-shell.git``

## 2. Install Dependencies

``zypper install libqt5-creator mpv-devel libcaca-devel ncurses5-devel libQt5WebView5 libSDL2-devel qconf messagelib-devel libqt5-qtwebengine-devel libopenssl-devel rpmdevtools nodejs8 libQt5WebChannel5-imports libqt5-qtwebengine libQt5QuickControls2-5 libqt5-qtquickcontrols libqt5-qtquickcontrols2``

## 3. Compile Stremio

``cd stremio-shell``    

``qmake-qt5``

``make``

## 4. Prepare the streaming server

Upon running the ./stremio binary, stremio should start up as usual. Except it won't start the streaming server, for this you need to have NodeJS installed and server.js, stremio.asar in your working dir, for which you need to do:

``wget https://dl.strem.io/four/v4.4.25/server.js ; wget https://dl.strem.io/four/v4.4.25/stremio.asar``

## 5. Run the streaming server

In one terminal you can execute:

``node server.js``

## 6. Run Stremio

``./stremio``

It can appear a popup window stating:

Error while starting streaming server. Please consider re-installing Stremio from https://www.stremio.com


However the system will be able to work normally. Cheers!
