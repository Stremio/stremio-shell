
VERSION := $(shell grep -oPm1 'VERSION=\K.+' stremio.pro)

DEST_DIR := dist-linux
RELEASE_DIR := release
QT_BIN_PATH ?= /usr/share/qt5

ICON_BIN := images/stremio.png

SERVER_JS := ${DEST_DIR}/server.js
STREMIO_DESKTOP := stremio.desktop

STREMIO_BIN := build/stremio
NODE_BIN := $(shell which node)
FFMPEG_BIN := $(shell which ffmpeg)

QT_RESOURCES = ${QT_BIN_PATH}/resources
QT_TRANSLATIONS = ${QT_BIN_PATH}/translations

ALL: release

dist: ${STREMIO_BIN} ${NODE_BIN} ${FFMPEG_BIN} ${ICON_BIN} ${STREMIO_DESKTOP}
	mkdir -p ${DEST_DIR}
	cp $^ ${DEST_DIR}/

libexec: ${QT_RESOURCES} ${QT_TRANSLATIONS}
	mkdir -p ${DEST_DIR}/libexec
	cp -r $^ ${DEST_DIR}/libexec/

server: dist
	wget "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v${VERSION}/server.js" -qO ${SERVER_JS} || rm ${SERVER_JS}

release: server libexec
	mkdir -p ${RELEASE_DIR}
	tar -pczf "${RELEASE_DIR}/Srtemio ${VERSION}.tar.gz" ${DEST_DIR}/*

clean:
	rm -rf ${DEST_DIR} ${RELEASE_DIR}
