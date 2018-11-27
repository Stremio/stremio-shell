#!/bin/bash

git clone https://github.com/Stremio/stremio-shell.git
cd stremio-shell
git submodule update --init

cp dist-utils/common/description ./description-pak
cp dist-utils/common/postinstall ./postinstall-pak
cp dist-utils/common/preremove ./preremove-pak

make -f release.makefile clean
make -f release.makefile
sudo checkinstall --default --install=no --fstrans=yes --pkgname stremio --pkgversion 4.4.10 --pkggroup video --pkglicense="MIT" --nodoc --pkgarch=$(dpkg --print-architecture) --requires="nodejs,libmpv1 \(\>=0.27.2\),qml-module-qt-labs-platform \(\>=5.9.5\),qml-module-qtquick-controls \(\>=5.9.5\),qml-module-qtquick-dialogs \(\>=5.9.5\),qml-module-qtwebchannel \(\>=5.9.5\),qml-module-qtwebengine \(\>=5.9.5\)" make -f release.makefile install
