# tcz-jivelite
piCoPlayer /dev/fb jivelite.tcz

Build squeezeplay

git clone https://github.com/ralph-irving/squeezeplay

copy Makefile.picoplayer squeezeplay/src
copy squeezplay-lua.patch squeezeplay/src/lua-5.1.1

cd squeezeplay/src/lua-5.1.1
patch -p0 -i squeezplay-lua.patch

cd squeezeplay/src
make -f Makefile.picoplayer clean
make -f Makefile.picoplayer

Install squeezeplay

mkdir -p /opt/squeezeplay
tar -C /opt/squeezeplay ../build/squeezeplay-7.8.0-.tgz

Build jivelite

git clone https://github.com/ralph-irving/jivelite

copy jivelite-picoplayer.patch jivelite
cd jivelite
patch -p0 -i jivelite-picoplayer.patch

make

Install jivelite

mkdir -p /opt/jivelite

./jivelite-install

Make jivelite squash filesystem

./jivelite-maketcz

