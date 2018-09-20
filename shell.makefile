ALL: build/stremio

build/stremio: build
	cd build && qmake .. && make -j

build:
	mkdir $@

#stremio-shell:
#	git clone https://github.com/Stremio/stremio-shell.git && cd stremio-shell && git submodule update --init && patch -p1 < ../stremio.pro.patch

clean:
	rm -fr build stremio-shell
