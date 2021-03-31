#!/bin/bash

git clone https://github.com/Stremio/stremio-shell.git
cd stremio-shell
if [ -n "$1" ]; then
	git checkout "$1"
fi
git submodule update --init

cp dist-utils/common/description ./description-pak
cp dist-utils/common/postinstall ./postinstall-pak
cp dist-utils/common/preremove ./preremove-pak

make -f release.makefile clean
make -f release.makefile
sudo checkinstall --default --install=no --fstrans=yes --pkgname stremio --pkgversion "$(./dist-utils/common/get-version.sh)" --pkggroup video --pkglicense="MIT" --nodoc --pkgarch=$(dpkg --print-architecture) --requires="nodejs,libmpv1 \(\>=0.30.0\),qml-module-qt-labs-platform \(\>=5.9.5\),qml-module-qtquick-controls \(\>=5.9.5\),qml-module-qtquick-dialogs \(\>=5.9.5\),qml-module-qtwebchannel \(\>=5.9.5\),qml-module-qtwebengine \(\>=5.9.5\),qml-module-qt-labs-folderlistmodel \(\>=5.9.5\),qml-module-qt-labs-settings \(\>=5.9.5\),librubberband2 \(\>=1.8.1\),libuchardet0  \(\>=0.0.6\),libfdk-aac1  \(\>=0.1.5\)" make -f release.makefile install
