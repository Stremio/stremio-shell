FROM ubuntu:18.04
RUN apt update
RUN apt install -y build-essential nodejs npm qt5-default qtdeclarative5-dev qtwebengine5-dev qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qt-labs-platform
RUN apt install -y wget 
RUN apt-get install -y libmpv-dev 
WORKDIR /build-stremio
ADD . /build-stremio

ENV QT_SELECT=5

#RUN make -f AppImage.makefile

