# Maintainer: Vladimir Borisov <vladimir@stremio.com>
_pkgname=stremio
pkgname=${_pkgname}-git
pkgver=4.4.10.r40.7f05671
pkgrel=1
pkgdesc="The next generation media center"
arch=($(uname -m))
url="https://stremio.com"
license=("unknown")
groups=()
depends=(nodejs ffmpeg qt5-webengine qt5-webchannel qt5-declarative qt5-quickcontrols qt5-quickcontrols2 qt5-translations mpv openssl)
makedepends=("git" "wget" "qt5-tools" "librsvg" "imagemagick")
provides=("${_pkgname}")
conflicts=("${_pkgname}")
replaces=()
backup=()
options=()

cat <(echo 'post_install() {') postinstall-pak <(echo '}') <(echo 'pre_remove() {') preremove-pak <(echo '}') > stremio.install

install=stremio.install

# TODO: change back to master/remove the #fragment
source=()
noextract=()
md5sums=()

# Please refer to the 'USING git SOURCES' section of the PKGBUILD man page for
# a description of each element in the source array.

pkgver() {
	cd "$startdir"
# Git, tags available
	printf "%s" "$(git describe --long | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"

# Git, no tags available
#	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
	cd "$startdir"
	git submodule update --init
	make -f release.makefile clean
}

build() {
	cd "$startdir"
	make -f release.makefile PREFIX="$pkgdir"
}

package() {
	cd "$startdir"
	export PREFIX="$pkgdir";
	make -f release.makefile install
}
