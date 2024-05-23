#!/bin/bash
#
JIVELITE=jivelite
JIVELITEVERSION=8.0.0
SRC=${JIVELITE}
LOG=$PWD/config.log
OUTPUT=$PWD/${JIVELITE}-build
LUAOUTPUT=$PWD/lua-build
TCZ="${JIVELITE}_touch.tcz"
TCZINFO="pcp-${JIVELITE}.tcz.info"
LUATCZ="pcp-lua.tcz"
LUATCZINFO="${LUATCZ}.info"
ARCH=$(uname -m)

# Build requires these extensions
tce-load -i compiletc squashfs-tools git libasound-dev patchelf pcp-squeezeplay pcp-squeezeplay-dev pcp-lirc-dev pcp-lirc

## Start
echo "Most log mesages sent to $LOG... only 'errors' displayed here"
date > $LOG

## Build
echo "Cleaning up..."

if [ -d $OUTPUT ]; then
	rm -rf $OUTPUT >> $LOG
fi

mkdir -p $OUTPUT

if [ -d $LUAOUTPUT ]; then
	rm -rf $LUAOUTPUT >> $LOG
fi

mkdir -p $LUAOUTPUT

echo "Compiling..."

./compile-jivelite.sh >> $LOG

if [ "$?" -ne "0" ]; then
	echo "Compiled failed!"
	exit 1
fi

echo "Installing in $OUTPUT..."
cd $SRC
mkdir -p $OUTPUT/opt/jivelite/bin
cp -p bin/jivelite $OUTPUT/opt/jivelite/bin
mkdir -p $OUTPUT/opt/jivelite/lib
cp -pr lib $OUTPUT/opt/jivelite
cp -pr share $OUTPUT/opt/jivelite

cd /tmp/tcloop/pcp-squeezeplay/opt/squeezeplay/lib
tar -cf - libexpat.so* libfreetype.so* libjpeg.so* libpng.so* libpng12.so* libSDL_gfx.so* libSDL_image-1.2.so.* libSDL_ttf-2.0.so* libSDL-1.2.so* | (cd $OUTPUT/opt/jivelite/lib; tar -xvf -)

if [ "$ARCH" == "aarch64" ]; then
        echo "$ARCH detected."
	tar -cf - libz.so* | (cd $OUTPUT/opt/jivelite/lib; tar -xvf -)
fi

# Install lua
cp -p $OUTPUT/../$SRC/lua-5.1.5/src/{lua,luac} $OUTPUT/opt/jivelite/bin
cp -p $OUTPUT/../$SRC/lua-5.1.5/src/liblua.so $OUTPUT/opt/jivelite/lib

# Remove user contributed VU Meters, they are installed as tcz packages
cd $OUTPUT/opt/jivelite || exit 1
rm share/jive/applets/WQVGAsmallSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_d.png
rm share/jive/applets/WQVGAsmallSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_e.png
rm share/jive/applets/WQVGAsmallSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_j.png
rm share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_b.png
rm share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png
rm share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_d.png
rm share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_e.png
rm share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_j.png

# Replace jivelite splash screen
cp -p $OUTPUT/../pcp.png share/jive/jive/splash.png

# Allow jivelite to receive power off notifications
patch -p0 -i$OUTPUT/../pcp-JiveMain-GenericBrightness.patch || exit 1
patch -p0 -i$OUTPUT/../pcp-ScreenSaversApplet-lua.patch || exit 1
patch -p0 -i$OUTPUT/../pcp-System-lua.patch || exit 1

# Set JogglerSkin as the default.
patch -p0 -i$OUTPUT/../jivelite-defaultjogglerskin.patch || exit 1

# Enable lirc IR support
# patch -p0 -i$OUTPUT/../jivelite-irbsp.patch || exit 1

# Only look for our shared libraries in /opt/jivelite/lib
find lib -type f -name '*so*' -exec patchelf --set-rpath "/opt/jivelite/lib" {} \;

# Include /usr/local/lib in library search patch so SDL/SDLgfx can load libts
patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL-1.2.so.0.11.?
#patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL_gfx.so.13.9.1
patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL_gfx.so.0.0.15
find bin -type f -exec patchelf --set-rpath "/opt/jivelite/lib" {} \;

# Keep the install as small as possible
find bin -type f -exec strip --strip-unneeded {} \;
#find lib -type f -name '*so*' -exec strip --strip-unneeded {} \;

# ffi not supported for standard lua
patch -p0 -i$OUTPUT/../$SRC/scripts/remove-ffi.patch

# Install applet to enable turning the rpi backlight off
cp -pr $OUTPUT/../DisplayOff $OUTPUT/opt/jivelite/share/jive/applets/

# Install applet to enable turning the rpi backlight off
cp -pr $OUTPUT/../piCorePlayer $OUTPUT/opt/jivelite/share/jive/applets/

# Install util applet for backlight functions
cp -pr $OUTPUT/../utils $OUTPUT/opt/jivelite/share/jive/jive/

# Install script to restart jivelite after a Quit
cp -p $OUTPUT/../jivelite-sp $OUTPUT/opt/jivelite/bin/jivelite.sh
chmod 755 $OUTPUT/opt/jivelite/bin/jivelite.sh

# Allow removal of Quit from home menu
cd $OUTPUT/opt/jivelite/bin
ln -s jivelite jivelite-sp

echo "Building tcz"
cd $OUTPUT >> $LOG

if [ -f $OUTPUT/../lua.tar ]; then
	rm $OUTPUT/../lua.tar
fi

tar -cf $OUTPUT/../lua.tar opt/jivelite/bin/{lua,luac} opt/jivelite/lib/liblua.so opt/jivelite/share/lua opt/jivelite/lib/lua

cd $OUTPUT/.. >> $LOG

if [ -f $TCZ ]; then
	rm $TCZ >> $LOG
fi

mksquashfs $OUTPUT $TCZ -all-root -no-progress >> $LOG
md5sum `basename $TCZ` > ${TCZ}.md5.txt

cd $LUAOUTPUT >> $LOG
tar -xf $OUTPUT/../lua.tar
mkdir -p usr/bin
mv opt/jivelite/bin/{lua,luac} usr/bin
rmdir opt/jivelite/bin

cd $LUAOUTPUT/..

if [ -f $LUATCZ ]; then
	rm $LUATCZ >> $LOG
fi

case $ARCH in
	aarch64) BLOCKSIZE=16384 ;;
	*) BLOCKSIZE=4096 ;;
esac

mksquashfs $LUAOUTPUT $LUATCZ -b $BLOCKSIZE -all-root -no-progress >> $LOG
md5sum `basename $LUATCZ` > $LUATCZ.md5.txt

cd $LUAOUTPUT >> $LOG
find * -not -type d > $OUTPUT/../${LUATCZ}.list
 
cd $OUTPUT/../
echo -e "Title:\t\t$LUATCZ" > $LUATCZINFO
echo -e "Description:\tLua a powerful, efficient, lightweight, embeddable scripting language." >> $LUATCZINFO
echo -e "Version:\t5.1.5" >> $LUATCZINFO
echo -e "Commit:\t\t$(cd $SRC; git show | grep commit | awk '{print $2}')" >> $LUATCZINFO
echo -e "Authors:\thttp://www.lua.org/authors.html" >> $LUATCZINFO
echo -e "Original-site:\thttp://www.lua.org/" >> $LUATCZINFO
echo -e "Copying-policy:\tMIT http://www.lua.org/license.html" >> $LUATCZINFO
echo -e "Size:\t\t$(ls -lk $LUATCZ | awk '{print $5}')" >> $LUATCZINFO
echo -e "Extension_by:\tpiCorePlayer team: http://www.picoreplayer.org/" >> $LUATCZINFO
echo -e "\t\tCompiled for piCore 14.x" >> $LUATCZINFO

./split-jivelite-tcz.sh

echo -e "Title:\t\tpcp-$JIVELITE.tcz" > $TCZINFO
echo -e "Description:\tCommunity squeezebox controller." >> $TCZINFO
echo -e "Version:\t$(awk -F\" '{printf "%s", $2}' jivelite/src/version.h)" >> $TCZINFO
echo -e "Commit:\t\t$(cd $SRC; git show | grep commit | awk '{print $2}')" >> $TCZINFO
echo -e "Authors:\tAdrian Smith, Ralph Irving, Michael Herger" >> $TCZINFO
echo -e "Original-site:\t$(grep url $SRC/.git/config | awk '{print $3}')" >> $TCZINFO
echo -e "Copying-policy:\tGPLv3" >> $TCZINFO
echo -e "Size:\t\t$(ls -lk pcp-$JIVELITE.tcz | awk '{print $5}')" >> $TCZINFO
echo -e "Extension_by:\tpiCorePlayer team: http://www.picoreplayer.org/" >> $TCZINFO
echo -e "\t\tCompiled for piCore 14.x" >> $TCZINFO

./create-vumeters-tcz.sh

cp -p $TCZINFO pcp-jivelite_hdskins.tcz.info
sed -i "s#pcp-$JIVELITE.tcz#pcp-jivelite_hdskins.tcz#" pcp-jivelite_hdskins.tcz.info
sed -i -e '/^Size:*/d' pcp-jivelite_hdskins.tcz.info
cp -p $TCZINFO pcp-jivelite_qvgaskins.tcz.info
sed -i "s#pcp-$JIVELITE.tcz#pcp-jivelite_qvgaskins.tcz#" pcp-jivelite_qvgaskins.tcz.info
sed -i -e '/^Size:*/d' pcp-jivelite_qvgaskins.tcz.info
cp -p $TCZINFO pcp-jivelite_wqvgaskins.tcz.info
sed -i "s#pcp-$JIVELITE.tcz#pcp-jivelite_wqvgaskins.tcz#" pcp-jivelite_wqvgaskins.tcz.info
sed -i -e '/^Size:*/d' pcp-jivelite_wqvgaskins.tcz.info

./create-vumeters-alex-tcz.sh
