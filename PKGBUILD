# Maintainer: Vladimir Borisov <vladimir@stremio.com>
_pkgname=stremio
pkgname=${_pkgname}-git
pkgver=4.4.10.r19.78a80ef
pkgrel=1
pkgdesc="The next generation media center"
arch=(any)
url="https://stremio.com"
license=("unknown")
groups=()
depends=(ffmpeg qt5-webengine qt5-webchannel qt5-declarative qt5-quickcontrols qt5-quickcontrols2 qt5-translations mpv openssl)
makedepends=("git" "nodejs" "qt5-tools")
provides=("${_pkgname}")
conflicts=("${_pkgname}")
replaces=()
backup=()
options=()
install=

# TODO: change back to master/remove the #fragment
source=("${_pkgname}::git+https://github.com/Stremio/stremio-shell.git#branch=appimage" "server.js::https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/master/server.js")
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
	#VERSION=$(grep -oPm1 'VERSION=\K.+' stremio.pro)
	#echo -e "isEmpty(PREFIX) {\n PREFIX = /opt\n}\ntarget.path = \$\$PREFIX/\$\${TARGET}\nexport(target.path)\nINSTALLS += target\nexport(INSTALLS)" > deployment.pri
	mkdir -p build && cd build
	qmake PREFIX="$pkgdir" ..
	make -j
	#wget "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v$VERSION/server.js" -q || rm server.js
}

package() {
	INSTALL_DIR="$pkgdir/opt/${_pkgname}"
	# mkdir -p "$INSTALL_DIR"
	install -D "$srcdir/${_pkgname}/build/stremio"\
	"$srcdir/server.js"\
	"$(which node)"\
	"$srcdir/${_pkgname}/stremio.desktop"\
	"$srcdir/${_pkgname}/images/stremio.svg" "$INSTALL_DIR"
	mkdir -p "$pkgdir/usr/share/applications"
	mkdir -p "$pkgdir/usr/bin"
	ln -s "$INSTALL_DIR/stremio.desktop" "$pkgdir/usr/share/applications/stremio.desktop"
	ln -s "$INSTALL_DIR/stremio" "$pkgdir/usr/bin/stremio"
}
