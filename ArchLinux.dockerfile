FROM base/devel

RUN pacman -Syu --noconfirm
RUN pacman -S --needed --noconfirm sudo git wget librsvg
RUN useradd builduser -m
RUN passwd -d builduser
RUN echo 'builduser ALL=(ALL) ALL' >> /etc/sudoers

WORKDIR /home/builduser

ADD PKGBUILD .
ADD stremio.install .

#RUN sudo -u builduser bash -c 'git clone https://github.com/Stremio/stremio-shell.git && cd stremio-shell && git checkout debian && makepkg --syncdeps --noconfirm'
RUN sudo -u builduser bash -c 'makepkg --syncdeps --noconfirm'
