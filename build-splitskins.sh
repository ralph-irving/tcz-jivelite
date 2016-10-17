#!/bin/bash
if [ -f jivelite_touch_orig.tcz ]; then
	rm jivelite_touch_orig.tcz
fi

if [ -d jivelite-build ]; then
	rm -rf jivelite-build
fi

cp -p jivelite_touch.tcz jivelite_touch_orig.tcz

unsquashfs jivelite_touch_orig.tcz 
mv squashfs-root jivelite-build

if [ -f hdskins.tar.gz ]; then
	rm hdskins.tar.gz
fi

tar -czf hdskins.tar.gz jivelite-build/opt/jivelite/share/jive/applets/{HDGridSkin,HDSkin}

if [ -f wqvgaskins.tar.gz ]; then
	rm wqvgaskins.tar.gz
fi

tar -czf wqvgaskins.tar.gz jivelite-build/opt/jivelite/share/jive/applets/{WQVGAlargeSkin,WQVGAsmallSkin}

if [ -f qvgaskins.tar.gz ]; then
	rm qvgaskins.tar.gz
fi

tar -czf qvgaskins.tar.gz jivelite-build/opt/jivelite/share/jive/applets/{QVGAbaseSkin,QVGAlandscapeSkin,QVGAportraitSkin}

rm hdskins.tar.gz
rm wqvgaskins.tar.gz
rm qvgaskins.tar.gz

rm -rf jivelite-build/opt/jivelite/share/jive/applets/{HDGridSkin,HDSkin}
rm -rf jivelite-build/opt/jivelite/share/jive/applets/{WQVGAlargeSkin,WQVGAsmallSkin}
rm -rf jivelite-build/opt/jivelite/share/jive/applets/{QVGAbaseSkin,QVGAlandscapeSkin,QVGAportraitSkin}

cp -p pcp.png jivelite-build/opt/jivelite/share/jive/jive/splash.png

if [ -f jivelite_touch.tcz ]; then
	rm jivelite_touch.tcz
fi

mksquashfs jivelite-build jivelite_touch.tcz -all-root -no-progress

rm -rf jivelite-build
tar -xzf hdskins.tar.gz

if [ -f jivelite_hdskins.tcz ]; then
	rm jivelite_hdskins.tcz
fi

mksquashfs jivelite-build jivelite_hdskins.tcz -all-root -no-progress

rm -rf jivelite-build
tar -xzf wqvgaskins.tar.gz

if [ -f jivelite_wqvgaskins.tcz ]; then
	rm jivelite_wqvgaskins.tcz
fi

mksquashfs jivelite-build jivelite_wqvgaskins.tcz -all-root -no-progress

rm -rf jivelite-build
tar -xzf qvgaskins.tar.gz

if [ -f jivelite_qvgaskins.tcz ]; then
	rm jivelite_qvgaskins.tcz
fi

mksquashfs jivelite-build jivelite_qvgaskins.tcz -all-root -no-progress

rm -rf jivelite-build

