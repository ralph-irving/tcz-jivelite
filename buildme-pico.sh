#!/bin/sh

JIVELITE=jivelite
JIVELITEVERSION=0.1
SRC=${JIVELITE}
LOG=$PWD/config.log
OUTPUT=$PWD/${JIVELITE}-build
TCZ="${JIVELITE}_touch.tcz"

# Build requires these extra packages in addition to the raspbian 7.6 build tools
# sudo apt-get install squashfs-tools bsdtar

## Start
echo "Most log mesages sent to $LOG... only 'errors' displayed here"
date > $LOG

## Build
echo "Cleaning up..."

if [ -d $OUTPUT ]; then
	rm -rf $OUTPUT >> $LOG
fi

mkdir -p $OUTPUT

cd $SRC >> $LOG
SVNVERSION=`svnversion`
make clean

echo "Running make..."
make >> $LOG

echo "Installing in $OUTPUT..."
mkdir -p $OUTPUT/opt/jivelite/bin
cp -p bin/jivelite $OUTPUT/opt/jivelite/bin
mkdir -p $OUTPUT/opt/jivelite/lib
cp -pr lib $OUTPUT/opt/jivelite
cp -pr share $OUTPUT/opt/jivelite
#cd /opt/squeezeplay/lib
#tar -cf - libexpat.so* libfreetype.so* libjpeg.so* libpng.so* libpng12.so* libSDL_gfx.so* libSDL_image-1.2.so.* libSDL_ttf-2.0.so* libSDL-1.2.so* | (cd $OUTPUT/opt/jivelite/lib; tar -xvf -)
cp -p $OUTPUT/../$SRC/lua-5.1.1/src/{lua,luac} $OUTPUT/opt/jivelite/bin
cp -p $OUTPUT/../$SRC/lua-5.1.1/src/liblua.so $OUTPUT/opt/jivelite/lib
cd $OUTPUT/opt || exit 1
find jivelite -type d -name '.svn' -exec rm -rf {} \;
#cd $HOME/source/squeezeplay/build/linux/lib || exit 1
#tar -cf - libSDL-1.2.so* libSDL_gfx.so* | (cd $OUTPUT/opt/jivelite/lib; tar -xvf -)
cd $OUTPUT/opt/jivelite/lib || exit 1
tar -xzf $OUTPUT/../jivelite-pico-libs.tar.gz
cd $OUTPUT/opt/jivelite || exit 1
find lib -type f -name '*so*' -exec patchelf --set-rpath "/opt/jivelite/lib" {} \;
#find lib -type f -name '*so*' -exec strip --strip-unneeded {} \;
patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL-1.2.so.0.11.4
patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL_gfx.so.13.9.1
find bin -type f -exec patchelf --set-rpath "/opt/jivelite/lib" {} \;
find bin -type f -exec strip --strip-unneeded {} \;
patch -p0 -i$OUTPUT/../$SRC/scripts/remove-ffi.patch
cp -p $OUTPUT/../jivelite-sp $OUTPUT/opt/jivelite/bin

echo "Building tcz"
cd $OUTPUT/.. >> $LOG

if [ -f $TCZ ]; then
	rm $TCZ >> $LOG
fi

mksquashfs $OUTPUT $TCZ -all-root >> $LOG
md5sum `basename $TCZ` > ${TCZ}.md5.txt

#echo "$TCZ contains"
#unsquashfs -ll $TCZ

# Make tarball for debian wheezy rpi install
cd $OUTPUT/opt/jivelite/lib
tar -xzf $OUTPUT/../libts-pico.tar.gz
find $OUTPUT/opt/jivelite/lib -type f -name '*\.la' -exec rm {} \;

# Manually add to relaunch script /usr/local/bin/jivelite
TSLIB_CONFFILE=/opt/jivelite/lib/ts.conf
TSLIB_PLUGINDIR=/opt/jivelite/lib/ts

echo "module_raw input"  > $OUTPUT/$TSLIB_CONFFILE
echo "module pthres pmin=1" >> $OUTPUT/$TSLIB_CONFFILE
echo "module variance delta=30" >> $OUTPUT/$TSLIB_CONFFILE
echo "module dejitter delta=100" >> $OUTPUT/$TSLIB_CONFFILE
echo "module linear" >> $OUTPUT/$TSLIB_CONFFILE

echo "63975 7 724784 2 62927 574656 65536 800 480" > $OUTPUT/opt/jivelite/lib/pointercal

cd $OUTPUT/opt/jivelite/bin
if [ -f jivelite-sp ]; then
	rm jivelite-sp
fi
ln -s jivelite jivelite-sp

cd $OUTPUT/opt/jivelite
if [ -f $OUTPUT/../$JIVELITE-$JIVELITEVERSION-$SVNVERSION.tar.gz ]; then
	rm $OUTPUT/../$JIVELITE-$JIVELITEVERSION-$SVNVERSION.tar.gz
fi

tar -czf $OUTPUT/../$JIVELITE-$JIVELITEVERSION-$SVNVERSION.tar.gz bin/ lib/ share/
