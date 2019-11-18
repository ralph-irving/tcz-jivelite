#!/bin/bash

if [ ! -d jivelite ]; then
	git clone https://github.com/ralph-irving/jivelite.git
	cd jivelite
	patch -p0 -i../jivelite-picoplayer.patch || exit 1
else
	cd jivelite
	make PREFIX=/usr clean
	patch -p0 -R -i../jivelite-picoplayer.patch
	git pull
	patch -p0 -i../jivelite-picoplayer.patch
fi

make

if [ ! -d lua-5.1.5 ]; then
	svn checkout https://github.com/ralph-irving/squeezeplay.git/trunk/src/lua-5.1.5
	cd lua-5.1.5
	patch -p0 -i../../squeezplay-lua.patch || exit 1
else
	cd lua-5.1.5
	make clean
	patch -R -p0 -i../../squeezplay-lua.patch
	svn up
	patch -p0 -i../../squeezplay-lua.patch
fi

make linux
