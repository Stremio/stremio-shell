# Build Stremio for OpenSuseLeap15

These instructions have been tested in OpenSuseLeap15

## 1. Start by cloning the GIT repository:

``git clone --recurse-submodules -j8 git://github.com/Stremio/stremio-shell.git``

## 2. Install Dependencies

``cmake zypper install libqt5-creator mpv-devel libcaca-devel ncurses5-devel libQt5WebView5 libSDL2-devel qconf messagelib-devel libqt5-qtwebengine-devel libopenssl-devel rpmdevtools nodejs8 libQt5WebChannel5-imports libqt5-qtwebengine libQt5QuickControls2-5 libqt5-qtquickcontrols libqt5-qtquickcontrols2``

## 3. Compile Stremio

``cd stremio-shell``    

``make -f release.makefile``

## 5. Install Stremio

Once build it can be installed with the following command:

``make -f release.makefile install``

## 6. Run Stremio

``stremio``

Cheers!
