# Build instructions for Fedora

These steps were tested on **Fedora 44** with Qt 5.15 and mpv 0.41. They
should also work on recent Fedora releases that still ship the Qt 5 stack.

## 1. Install dependencies

```bash
sudo dnf install -y \
  git make gcc-c++ cmake wget nodejs22 \
  qt5-qtbase-devel qt5-qtdeclarative-devel qt5-qtwebengine-devel \
  qt5-qtwebchannel-devel qt5-qtquickcontrols qt5-qtquickcontrols2 \
  qt5-qtwebengine qt5-qtwebchannel qt5-qtgraphicaleffects \
  mpv-devel openssl-devel librsvg2-tools
```

Notes:
- On Fedora, the libmpv development package is `mpv-devel` (it provides
  `pkgconfig(mpv)` and `/usr/lib64/libmpv.so`).
- Node.js is packaged with a version suffix; `nodejs22` is current on
  Fedora 44. Use whichever `nodejsXX` stream is available (e.g. `nodejs20`).
- `qt5-qtwebengine` and the `qml-module`-equivalent Qt Quick packages
  (`qt5-qtquickcontrols`, `qt5-qtquickcontrols2`, `qt5-qtgraphicaleffects`,
  `qt5-qtwebchannel`) are required at runtime for the QML UI.

## 2. Clone and build

```bash
git clone https://github.com/Stremio/stremio-shell.git
cd stremio-shell
git submodule update --init
make -f release.makefile
```

This produces the `build/stremio` binary, downloads the streaming
`server.js`, and renders the tray/app icons. The build links against the
system `libmpv.so` via pkg-config.

## 3. Install

```bash
sudo make -f release.makefile install PREFIX=/usr
```

The `install` target places the application under `/opt/stremio` (binary,
`server.js`, icons) and creates a `node` symlink used by the streaming
server.

### Desktop integration (optional)

If your desktop environment does not pick up a launcher automatically, you
can add one:

```bash
# a launcher on PATH
sudo tee /usr/bin/stremio >/dev/null <<'EOF'
#!/bin/sh
cd /opt/stremio || exit 1
exec /opt/stremio/stremio "$@"
EOF
sudo chmod +x /usr/bin/stremio

# desktop entry + icons
sudo cp /opt/stremio/smartcode-stremio.desktop /usr/share/applications/stremio.desktop
sudo sed -i 's#^Exec=.*#Exec=/usr/bin/stremio %u#; s#^Icon=.*#Icon=smartcode-stremio#' \
  /usr/share/applications/stremio.desktop
for s in 16 22 24 32 48 64 128 256; do
  sudo rsvg-convert images/stremio.svg -w "$s" -h "$s" \
    -o "/usr/share/icons/hicolor/${s}x${s}/apps/smartcode-stremio.png"
done
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor
sudo update-desktop-database /usr/share/applications
```

You can now launch Stremio from your application menu or by running
`stremio`.
