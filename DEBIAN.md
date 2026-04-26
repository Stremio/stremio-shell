# Build Stremio for Debian GNU/Linux

These instructions have been tested on Debian Trixie 13 and Sid (unstable).

## 1. Clone the repository

```bash
git clone --recurse-submodules https://github.com/vejeta/stremio-shell.git
cd stremio-shell
git checkout qt6-migration
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init
```

## 2. Install build dependencies

```bash
sudo apt-get install cmake g++ pkgconf libssl-dev libmpv-dev librsvg2-bin \
  qt6-base-dev qt6-declarative-dev qt6-webengine-dev qt6-webchannel-dev qt6-tools-dev libgl-dev
```

## 3. Build Stremio

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DQT_DEFAULT_MAJOR_VERSION=6
make -j$(nproc)
```

## 4. Install runtime QML dependencies

If you see errors like `module "QtWebEngine" is not installed` when running, install:

```bash
sudo apt-get install qml6-module-qtwebengine qml6-module-qtwebchannel \
  qml6-module-qtquick-controls qml6-module-qtquick-dialogs
```

## 5. Prepare the streaming server

The stremio binary expects a Node.js server in the same directory:

```bash
cp ./server.js ./build/
ln -s "$(which node)" ./build/node
```

## 6. Run Stremio

```bash
./build/stremio
```

If you get a popup about the streaming server failing, make sure you completed step 5.
