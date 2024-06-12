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

sudo apt install libmpv1 qml-module-qt-labs-platform qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qtwebchannel qml-module-qtwebengine qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings libfdk-aac2

# need to use wget and fix x64 arch
#OpenSSL 1.1.1 End of Life MAR 28TH, 2023
# NEED UPDATE TO libssl3 and modify dependecy on libcrypto.so.1.1
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1-1ubuntu2.1~18.04.23_amd64.deb
sudo dpkg -i libssl1.1_1.1.1-1ubuntu2.1~18.04.23_amd64.deb
rm libssl1.1_1.1.1-1ubuntu2.1~18.04.23_amd64.deb
# WARNING STREMIO uses libcrypto.so.1.1 but pkg libssl1.1 (DarkmatterUAE commented 2 weeks ago) no longer being maintained by OpenSSL dev. https://www.openssl.org/blog/blog/2023/03/28/1.1.1-EOL/

sudo checkinstall --default --install=no --fstrans=yes --pkgname stremio --pkgversion "$(./dist-utils/common/get-version.sh)" --pkggroup video --pkglicense="MIT" --nodoc --pkgarch=$(dpkg --print-architecture) --requires="nodejs,libmpv1 \(\>=0.30.0\),qml-module-qt-labs-platform \(\>=5.9.5\),qml-module-qtquick-controls \(\>=5.9.5\),qml-module-qtquick-dialogs \(\>=5.9.5\),qml-module-qtwebchannel \(\>=5.9.5\),qml-module-qtwebengine \(\>=5.9.5\),qml-module-qt-labs-folderlistmodel \(\>=5.9.5\),qml-module-qt-labs-settings \(\>=5.9.5\),librubberband2 \(\>=1.8.1\),libuchardet0  \(\>=0.0.6\),libfdk-aac2 \(\>=2.0.2\),libssl1.1 \(\>=1.1.1\)" make -f release.makefile install

# it will fail install requires deps so
sudo apt --fix-broken install
