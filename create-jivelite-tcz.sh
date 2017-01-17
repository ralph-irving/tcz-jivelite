#!/bin/bash

JIVELITE=jivelite
JIVELITEVERSION=0.1.0
SRC=${JIVELITE}
LOG=$PWD/config.log
OUTPUT=$PWD/${JIVELITE}-build
LUAOUTPUT=$PWD/lua-build
TCZ="${JIVELITE}_touch.tcz"
TCZINFO="pcp-${JIVELITE}.tcz.info"
LUATCZ="pcp-lua.tcz"

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

if [ -d $LUAOUTPUT ]; then
	rm -rf $LUAOUTPUT >> $LOG
fi

mkdir -p $LUAOUTPUT

echo "Compiling..."

./compile-jivelite.sh >> $LOG

echo "Installing in $OUTPUT..."
cd $SRC
mkdir -p $OUTPUT/opt/jivelite/bin
cp -p bin/jivelite $OUTPUT/opt/jivelite/bin
mkdir -p $OUTPUT/opt/jivelite/lib
cp -pr lib $OUTPUT/opt/jivelite
cp -pr share $OUTPUT/opt/jivelite

# Install shared libraries from squeezeplay build
cd /opt/squeezeplay/lib
tar -cf - libexpat.so* libfreetype.so* libjpeg.so* libpng.so* libpng12.so* libSDL_gfx.so* libSDL_image-1.2.so.* libSDL_ttf-2.0.so* libSDL-1.2.so* | (cd $OUTPUT/opt/jivelite/lib; tar -xvf -)

# Install lua
cp -p $OUTPUT/../$SRC/lua-5.1.1/src/{lua,luac} $OUTPUT/opt/jivelite/bin
cp -p $OUTPUT/../$SRC/lua-5.1.1/src/liblua.so $OUTPUT/opt/jivelite/lib

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
patch -p0 -i$OUTPUT/../pcp-JiveMain-lua.patch
patch -p0 -i$OUTPUT/../pcp-ScreenSaversApplet-lua.patch
patch -p0 -i$OUTPUT/../pcp-System-lua.patch

# Set JogglerSkin as the default.
patch -p0 -i$OUTPUT/../jivelite-defaultjogglerskin.patch

# Only look for our shared libraries in /opt/jivelite/lib
find lib -type f -name '*so*' -exec patchelf --set-rpath "/opt/jivelite/lib" {} \;

# Include /usr/local/lib in library search patch so SDL/SDLgfx can load libts
patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL-1.2.so.0.11.4
patchelf --set-rpath "/opt/jivelite/lib:/usr/local/lib" lib/libSDL_gfx.so.13.9.1
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

# Install script to restart jivelite after a Quit
cp -p $OUTPUT/../jivelite-sp $OUTPUT/opt/jivelite/bin/jivelite.sh

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

mksquashfs $LUAOUTPUT $LUATCZ -all-root -no-progress >> $LOG
md5sum `basename $LUATCZ` > $LUATCZ.md5.txt

cd $OUTPUT/../
./split-jivelite-tcz.sh

echo -e "Title:\t\tpcp-$JIVELITE.tcz" > $TCZINFO
echo -e "Description:\tLightweight headless squeezebox player." >> $TCZINFO
echo -e "Version:\t$JIVELITEVERSION" >> $TCZINFO
echo -e "Commit:\t\t$(cd $SRC; git show | grep commit | awk '{print $2}')" >> $TCZINFO
echo -e "Authors:\tAdrian Smith, Ralph Irving, Michael Herger" >> $TCZINFO
echo -e "Original-site:\t$(grep url $SRC/.git/config | awk '{print $3}')" >> $TCZINFO
echo -e "Copying-policy:\tGPLv3" >> $TCZINFO
echo -e "Size:\t\t$(ls -lk pcp-$JIVELITE.tcz | awk '{print $5}')k" >> $TCZINFO
echo -e "Extension_by:\tpiCorePlayer team: https://sites.google.com/site/picoreplayer" >> $TCZINFO
echo -e "\t\tCompiled for piCore 8.x" >> $TCZINFO

