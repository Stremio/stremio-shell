# Maintainer: Vladimir Borisov <vladimir@stremio.com>
_pkgname=stremio
pkgname=${_pkgname}-git
pkgver=4.4.10.r36.5886217
pkgrel=1
pkgdesc="The next generation media center"
arch=(any)
url="https://stremio.com"
license=("unknown")
groups=()
depends=(nodejs ffmpeg qt5-webengine qt5-webchannel qt5-declarative qt5-quickcontrols qt5-quickcontrols2 qt5-translations mpv openssl)
makedepends=("git" "qt5-tools" "imagemagick")
provides=("${_pkgname}")
conflicts=("${_pkgname}")
replaces=()
backup=()
options=()
install=stremio.install

# TODO: change back to master/remove the #fragment
source=("${_pkgname}::git+https://github.com/Stremio/stremio-shell.git#branch=debian" "server.js::https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/master/server.js")
noextract=()
md5sums=("SKIP" "SKIP")

# Please refer to the 'USING git SOURCES' section of the PKGBUILD man page for
# a description of each element in the source array.

pkgver() {
	cd "$srcdir/${_pkgname}"
# Git, tags available
	printf "%s" "$(git describe --long | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"

# Git, no tags available
#	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
	cd "$srcdir/${_pkgname}"
	git submodule update --init 
}

build() {
	cd "$srcdir/${_pkgname}"
	make -f release.makefile PREFIX="$pkgdir"
}

package() {
	cd "$srcdir/${_pkgname}"
	export PREFIX="$pkgdir";
	make -f release.makefile install
}
