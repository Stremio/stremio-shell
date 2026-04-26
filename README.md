## Build

This branch (`qt6-migration`) uses **Qt 6** and **CMake** as the build system.

### Dependencies

**Debian/Ubuntu:**
```bash
sudo apt install qt6-base-dev qt6-declarative-dev qt6-webengine-dev \
  qt6-webchannel-dev qt6-tools-dev libgl-dev libmpv-dev libssl-dev cmake
```

### Build instructions (all platforms)

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/vejeta/stremio-shell.git
cd stremio-shell
git checkout qt6-migration

# If you already cloned without --recurse-submodules:
git submodule update --init

# Build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DQT_DEFAULT_MAJOR_VERSION=6
make -j$(nproc)
```

### Platform-specific notes

- **Windows**: Refer to [WINDOWS.md](WINDOWS.md)
- **Debian**: Refer to [DEBIAN.md](DEBIAN.md)
- **OpenSuse Leap**: Refer to [OpenSuseLeap.md](OpenSuseLeap.md)
- **Docker**: See `./distros` directory and [DOCKER.md](DOCKER.md)

## Releasing a version

1. Bump the version in `CMakeLists.txt`
2. Create a git tag with the corresponding version

## Arguments

``--development``: would make the shell load from `http://127.0.0.1:11470` instead of `https://app.strem.io` and would force the shell to not try and start a streaming server

``--staging``: would load the web UI from `https://staging.strem.io`

``--webui-url=``: allows defining a different web UI URL

``--streaming-server``: when used with ``development``, it would make the shell try to start a streaming server; this is the default behaviour in production

``--autoupdater-force``: would force the auto-updater to check for a new version

``--autoupdater-force-full``: would force the auto-updater to always perform a full update (rather than partial)

``--autoupdater-endpoint=``: would override the default checking endpoints for the autoupdater

To test the autoupdater, you can use a command like: `./stremio --autoupdater-force --autoupdater-endpoint="https://www.stremio.com/updater/check?force=true"`; `force=true` passed to the update endpoint would cause it to always return the latest descriptor
