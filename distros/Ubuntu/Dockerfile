FROM ubuntu:18.04

# Import the required files
WORKDIR /build-stremio
ADD package.sh .

RUN mkdir -p /usr/share/desktop-directories

# Install package dependencies
RUN apt update && apt install -y git imagemagick checkinstall nodejs build-essential qt5-default qtdeclarative5-dev qtdeclarative5-dev-tools qtwebengine5-dev qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qt-labs-platform qml-module-qtwebchannel qml-module-qtwebengine wget libmpv-dev libssl-dev

# Build Stremio package
RUN ./package.sh
