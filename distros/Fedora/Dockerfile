FROM fedora:latest

# Install package dependencies
RUN dnf -y update
RUN dnf -y install which passwd sudo git wget make cmake gcc gcc-c++ qt5-qtwebchannel qt5-qtwebengine qt5-qtquickcontrols qt5-qtquickcontrols2 qt5-devel librsvg2-tools qt5-qtwebengine-devel openssl-devel nodejs rpmdevtools qtchooser jack-audio-connection-kit
RUN dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf -y install mpv-libs-devel

# Setting up new user
RUN useradd builduser -m
RUN passwd -d builduser
RUN echo 'builduser ALL=(ALL) ALL' >> /etc/sudoers
WORKDIR /home/builduser

# Import the required files
ADD stremio.spec .
ADD package.sh .
