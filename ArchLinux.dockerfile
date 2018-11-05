FROM base/devel

# Setting up new user
RUN useradd builduser -m
RUN passwd -d builduser
RUN echo 'builduser ALL=(ALL) ALL' >> /etc/sudoers
WORKDIR /home/builduser

# Import the required files
ADD PKGBUILD .
ADD stremio.install .

# Install package dependencies
RUN pacman -Syu --noconfirm
RUN pacman -S --needed --noconfirm sudo git wget librsvg

# Build Stremio package
RUN su builduser -c 'makepkg --syncdeps --noconfirm'
