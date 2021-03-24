
BUILD_DIR := build
INSTALL_DIR := ${PREFIX}/opt/stremio

ICON_BIN := smartcode-stremio.svg

SERVER_JS := server.js

STREMIO_BIN := ${BUILD_DIR}/stremio

ALL: ${STREMIO_BIN} ${SERVER_JS} icons

install:
	make -C ${BUILD_DIR} install
	install -Dm 644 ${SERVER_JS} "${INSTALL_DIR}/server.js"
	install -Dm 644 smartcode-stremio.desktop "${INSTALL_DIR}/smartcode-stremio.desktop"
	cp -r icons "${INSTALL_DIR}/"
	ln -s "${shell which node}" "${INSTALL_DIR}/node"
ifneq ("$(wildcard ../mpv-build/mpv/build)","")
	cp ../mpv-build/mpv/build/libmpv.so* "${INSTALL_DIR}/"
endif

uninstall:
	rm -f /usr/bin/stremio
	rm -fr "${INSTALL_DIR}"

icons:
	mkdir -p "$@"
	cd "$@" && printf 16,22,24,32,64,128 | xargs -I^ -d, sh -c 'rsvg-convert ../images/stremio.svg -w ^ -o smartcode-stremio_^.png && rsvg-convert ../images/stremio_tray_white.svg -w ^ -o smartcode-stremio-tray_^.png'

${SERVER_JS}: 
	wget "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v$(shell ./dist-utils/common/get-version.sh)/server.js" -qO ${SERVER_JS} || rm ${SERVER_JS}

${STREMIO_BIN}:
	mkdir -p ${BUILD_DIR}
	cd ${BUILD_DIR} && cmake -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${PREFIX}" ..
	make -j -C ${BUILD_DIR}

clean:
	rm -rf ${BUILD_DIR} ${SERVER_JS} icons

