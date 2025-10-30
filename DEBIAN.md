# Installing Stremio on Debian/Ubuntu

## Option 1: APT Repository (Recommended)

### Official Debian Package

**Stremio is officially packaged for Debian** by maintainer Juan Manuel Méndez Rey ([ITP #943703](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=943703)). The packages are currently under review for submission to the official Debian archive.

**Canonical source repositories** (Debian Salsa GitLab):
- https://salsa.debian.org/mendezr/stremio (main package - GPL-3.0)
- https://salsa.debian.org/mendezr/stremio-server (streaming server - proprietary)

For the easiest installation on Debian systems, use the APT repository:

### Installation Steps

#### Add Repository GPG Key

```bash
wget -qO - https://debian.vejeta.com/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/stremio-debian.gpg
```

#### Add Repository Source

Choose the appropriate repository for your Debian version:

**For Debian 13 (Trixie - current stable):**
```bash
echo "deb [signed-by=/usr/share/keyrings/stremio-debian.gpg] https://debian.vejeta.com trixie main non-free" | sudo tee /etc/apt/sources.list.d/stremio.list
```

**For Debian 12 (Bookworm - previous stable):**
```bash
echo "deb [signed-by=/usr/share/keyrings/stremio-debian.gpg] https://debian.vejeta.com bookworm main non-free" | sudo tee /etc/apt/sources.list.d/stremio.list
```

**For Debian sid (unstable) / Kali Rolling:**
```bash
echo "deb [signed-by=/usr/share/keyrings/stremio-debian.gpg] https://debian.vejeta.com sid main non-free" | sudo tee /etc/apt/sources.list.d/stremio.list
```

#### Install Stremio

```bash
sudo apt update
sudo apt install stremio stremio-server
```

### Available Packages

- **stremio** (main/free) - Desktop client with Qt5/QML interface (GPL-3.0, required)
- **stremio-server** (non-free) - BitTorrent streaming server (proprietary, optional but recommended)

### Tested Distributions

- ✅ Debian 13 (Trixie)
- ✅ Debian 12 (Bookworm)
- ✅ Debian sid (unstable)
- ✅ Kali Linux (rolling)

**Ubuntu**: Installation should work similarly on Ubuntu 22.04+ (untested). Use the trixie repository for Ubuntu users.

### Benefits of APT Repository

- **Automatic updates**: Receive new versions via regular `apt upgrade`
- **Dependency handling**: APT automatically installs all required dependencies
- **GPG signed**: Packages are cryptographically signed for security
- **System integration**: Proper integration with desktop environments and system libraries

---

## Building Debian Packages

For proper system integration, you can build Debian packages using `dpkg-buildpackage`.

### Requirements

- Debian/Ubuntu system with development tools
- Complete build dependencies (listed in `debian/control`)
- Understanding of Debian packaging workflow

### Reference Implementation

The official Debian packages use:
- **100% system libraries** (no bundled dependencies)
- **FHS compliant installation** (no `/opt` directory)
- **Proper license separation** (GPL client in main, proprietary server in non-free)

See the canonical source repositories for packaging details:
- https://salsa.debian.org/mendezr/stremio
- https://salsa.debian.org/mendezr/stremio-server

### Build Command

```bash
QT_DEFAULT_MAJOR_VERSION=5 dpkg-buildpackage -us -uc
```

This generates `.deb` packages that can be installed with `dpkg -i`.

---

## Known Issues & Solutions

### QtWebEngine Initialization

Stremio requires QtWebEngine to be initialized before the QApplication constructor. This is handled automatically in the official packages.

### QML Module Dependencies

All QML modules must be available at runtime. The APT repository packages declare these as dependencies, ensuring automatic installation.

### Streaming Server Environment

The streaming server (server.js) requires certain environment variables (HOME, USER, PWD) to function correctly. Official packages configure this automatically.

---

## Contributing

### Package Maintenance

Official Debian packages are maintained at:
- **Salsa GitLab** (canonical source): https://salsa.debian.org/mendezr/
- **GitHub** (CI/CD and releases): https://github.com/vejeta/stremio-debian

### Bug Reports

- **Debian packaging issues**: File at https://github.com/vejeta/stremio-debian/issues
- **Stremio application issues**: File at https://github.com/Stremio/stremio-shell/issues

### ITP Status

**Intent To Package** filed as [Debian Bug #943703](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=943703).

Packages are prepared for submission to the official Debian archive and are currently under review.

### Contact

**Maintainer**: Juan Manuel Méndez Rey
**Email**: vejeta@gmail.com
**Salsa**: https://salsa.debian.org/mendezr

---

## Additional Resources

- **Stremio Website**: https://www.stremio.com/
- **APT Repository**: https://debian.vejeta.com
- **GitHub Releases**: https://github.com/vejeta/stremio-debian/releases

---

*Last updated: October 2025*
