# Build Stremio on Ubuntu

These instructions were verified on Ubuntu 26.04 using the current `master` branch.

> [!NOTE]
> `DEBIAN.md` describes the older qmake build flow. The current `release.makefile`
> configures and builds Stremio with CMake.

## 1. Clone the repository

```sh
git clone --recurse-submodules -j8 https://github.com/Stremio/stremio-shell.git
cd stremio-shell
```

If the repository was cloned without submodules, initialize them before building:

```sh
git submodule update --init --recursive -j8
```

## 2. Install dependencies

```sh
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake pkgconf libssl-dev librsvg2-bin libmpv-dev \
  qtdeclarative5-dev qtwebengine5-dev nodejs \
  qml-module-qtwebchannel qml-module-qt-labs-platform \
  qml-module-qtwebengine qml-module-qtquick-dialogs \
  qml-module-qtquick-controls qml-module-qt-labs-settings \
  qml-module-qt-labs-folderlistmodel
```

`qtwebengine5-dev` is required by the current CMake configuration. Installing
`libqt5webview5-dev` alone does not provide the `Qt5WebEngine` CMake package.

## 3. Build

```sh
make -f release.makefile
```

This command builds `build/stremio`, downloads the streaming-server script to
`server.js`, and generates the application icons in `icons/`.

## 4. Run from the checkout

```sh
./build/stremio
```

## 5. Install system-wide

The repository install target installs Stremio and its streaming-server files
under `/opt/stremio`.

```sh
sudo make -f release.makefile install
sudo ln -sfn /opt/stremio/stremio /usr/local/bin/stremio
```

You can then run:

```sh
stremio
```

## 6. Add a desktop entry for the current user

The included `desktop_integration.sh` script installs a desktop entry below
`$XDG_DATA_HOME/applications` (or `~/.local/share/applications`). It uses
`build/stremio` by default:

```sh
./desktop_integration.sh --install
```

To register the system-wide installation instead, set `STREMIO_EXECUTABLE`:

```sh
STREMIO_EXECUTABLE=/opt/stremio/stremio ./desktop_integration.sh --install
```

Remove the per-user desktop entry with:

```sh
./desktop_integration.sh --uninstall
```
