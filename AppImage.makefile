
VERSION := $(shell grep -oPm1 'VERSION=\K.+' stremio.pro)

NSS_DIR := /usr/lib/x86_64-linux-gnu/nss

DEST_DIR := dist-linux
BUILD_DIR := build
RELEASE_DIR := release

QT_BIN_PATH ?= /usr/share/qt5

ICON_BIN := images/stremio.png

SERVER_JS := ${DEST_DIR}/server.js
STREMIO_DESKTOP := stremio.desktop

STREMIO_BIN := ${BUILD_DIR}/stremio
NODE_BIN := $(shell which node)
FFMPEG_BIN := $(shell which ffmpeg)

QT_RESOURCES = ${QT_BIN_PATH}/resources
QT_TRANSLATIONS = ${QT_BIN_PATH}/translations


APPIMAGE_FILE := Stremio-v${VERSION}-x86_64.AppImage


ALL: ${APPIMAGE_FILE}

${DEST_DIR}: ${STREMIO_BIN} ${NODE_BIN} ${FFMPEG_BIN} ${ICON_BIN} ${STREMIO_DESKTOP} ${QT_RESOURCES} ${QT_TRANSLATIONS}
	mkdir -p ${DEST_DIR}/lib
	cp -r $^ ${DEST_DIR}/
	cp -r ${NSS_DIR} ${DEST_DIR}/lib/

${APPIMAGE_FILE}: ${SERVER_JS} linuxdeployqt
	./linuxdeployqt --appimage-extract
	#This will create  Stremio-x86_64.AppImage
	./squashfs-root/AppRun ${DEST_DIR}/stremio -qmldir=. -bundle-non-qt-libs -appimage

${SERVER_JS}: ${DEST_DIR}
	wget "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v${VERSION}/server.js" -qO ${SERVER_JS} || rm ${SERVER_JS}

linuxdeployqt:
	wget "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" -qO $@ || rm $@
	chmod 700 $@

clean:
	rm -rf linuxdeployqt ${BUILD_DIR} ${DEST_DIR} ${RELEASE_DIR} ${APPIMAGE_FILE}

${STREMIO_BIN}: ${BUILD_DIR}
	cd ${BUILD_DIR} && qmake .. && make -j

${BUILD_DIR}:
	mkdir ${BUILD_DIR}

