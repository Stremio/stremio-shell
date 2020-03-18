#!/bin/bash

git clone https://github.com/mpv-player/mpv-build.git
pushd mpv-build
echo --enable-libmpv-shared > mpv_options
./rebuild
popd

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
sudo checkinstall --default --install=no --fstrans=yes --pkgname stremio --pkgversion "$(grep -oPm1 'VERSION=\K.+' stremio.pro)" --pkggroup video --pkglicense="MIT" --nodoc --pkgarch=$(dpkg --print-architecture) --requires="nodejs,qml-module-qt-labs-platform \(\>=5.9.5\),qml-module-qtquick-controls \(\>=5.9.5\),qml-module-qtquick-dialogs \(\>=5.9.5\),qml-module-qtwebchannel \(\>=5.9.5\),qml-module-qtwebengine \(\>=5.9.5\)" make -f release.makefile install
