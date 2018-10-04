
VERSION := $(shell grep -oPm1 'VERSION=\K.+' stremio.pro)

DEST_DIR := dist-linux
BUILD_DIR := build
INSTALL_DIR := /opt/stremio

ICON_BIN := images/stremio.svg

SERVER_JS := ${BUILD_DIR}/server.js
STREMIO_DESKTOP := stremio.desktop

STREMIO_BIN := ${BUILD_DIR}/stremio
NODE_BIN := $(shell which node)


ALL: ${DEST_DIR}

install:
	cp -r ${DEST_DIR} ${INSTALL_DIR}
	ln -s ${INSTALL_DIR}/${STREMIO_DESKTOP} /usr/share/applications/stremio.desktop
	ln -s ${INSTALL_DIR}/stremio /usr/bin/stremio

uninstall: ${INSTALL_DIR}
	rm -f /usr/bin/stremio
	rm -f /usr/share/applications/stremio.desktop
	rm -fr ${INSTALL_DIR}

deb:
	checkinstall --pkgname stremio --pkgversion 4.4.10 --pkggroup video --pkglicense="MIT" --nodoc --pkgarch=$(dpkg --print-architecture) make -f release.makefile install

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

${DEST_DIR}: ${STREMIO_BIN} ${NODE_BIN} ${ICON_BIN} ${STREMIO_DESKTOP} ${SERVER_JS}
	mkdir -p ${DEST_DIR}
	cp -r $^ ${DEST_DIR}/

${SERVER_JS}: ${BUILD_DIR}
	wget "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v${VERSION}/server.js" -qO ${SERVER_JS} || rm ${SERVER_JS}

${STREMIO_BIN}: ${BUILD_DIR}
	cd ${BUILD_DIR} && qmake .. && make -j

clean:
	rm -rf ${BUILD_DIR} ${DEST_DIR}

