FROM ubuntu:18.04
RUN apt update && apt install -y imagemagick checkinstall nodejs build-essential qt5-default qtdeclarative5-dev qtdeclarative5-dev-tools qtwebengine5-dev qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qt-labs-platform qml-module-qtwebchannel qml-module-qtwebengine wget libmpv-dev libssl-dev

WORKDIR /build-stremio
ADD . /build-stremio

RUN mkdir -p /usr/share/desktop-directories
RUN make -f release.makefile clean
RUN make -f release.makefile
RUN checkinstall --default --install=no --fstrans=yes --pkgname stremio --pkgversion 4.4.10 --pkggroup video --pkglicense="MIT" --nodoc --pkgarch=$(dpkg --print-architecture) --requires="nodejs,libmpv1 \(\>=0.27.2\),qml-module-qt-labs-platform \(\>=5.9.5\),qml-module-qtquick-controls \(\>=5.9.5\),qml-module-qtquick-dialogs \(\>=5.9.5\),qml-module-qtwebchannel \(\>=5.9.5\),qml-module-qtwebengine \(\>=5.9.5\)" make -f release.makefile install
