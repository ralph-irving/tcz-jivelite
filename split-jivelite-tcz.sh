#!/bin/bash
if [ -d jivelite-build ]; then
	rm -rf jivelite-build
fi

unsquashfs jivelite_touch.tcz 
mv squashfs-root jivelite-build

rm -rf jivelite-build/opt/jivelite/bin/{lua,luac} jivelite-build/opt/jivelite/lib/liblua.so jivelite-build/opt/jivelite/share/lua jivelite-build/opt/jivelite/lib/lua

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

rm -rf jivelite-build/opt/jivelite/share/jive/applets/{HDGridSkin,HDSkin}
rm -rf jivelite-build/opt/jivelite/share/jive/applets/{WQVGAlargeSkin,WQVGAsmallSkin}
rm -rf jivelite-build/opt/jivelite/share/jive/applets/{QVGAbaseSkin,QVGAlandscapeSkin,QVGAportraitSkin}

cp -p pcp.png jivelite-build/opt/jivelite/share/jive/jive/splash.png

if [ -f pcp-jivelite.tcz ]; then
	rm pcp-jivelite.tcz
fi

mksquashfs jivelite-build pcp-jivelite.tcz -all-root -no-progress
md5sum pcp-jivelite.tcz > pcp-jivelite.tcz.md5.txt

rm -rf jivelite-build
tar -xzf hdskins.tar.gz

if [ -f pcp-jivelite_hdskins.tcz ]; then
	rm pcp-jivelite_hdskins.tcz
fi

mksquashfs jivelite-build pcp-jivelite_hdskins.tcz -all-root -no-progress
md5sum pcp-jivelite_hdskins.tcz > pcp-jivelite_hdskins.tcz.md5.txt

rm -rf jivelite-build
tar -xzf wqvgaskins.tar.gz

if [ -f pcp-jivelite_wqvgaskins.tcz ]; then
	rm pcp-jivelite_wqvgaskins.tcz
fi

mksquashfs jivelite-build pcp-jivelite_wqvgaskins.tcz -all-root -no-progress
md5sum pcp-jivelite_wqvgaskins.tcz > pcp-jivelite_wqvgaskins.tcz.md5.txt

rm -rf jivelite-build
tar -xzf qvgaskins.tar.gz

if [ -f pcp-jivelite_qvgaskins.tcz ]; then
	rm pcp-jivelite_qvgaskins.tcz
fi

mksquashfs jivelite-build pcp-jivelite_qvgaskins.tcz -all-root -no-progress
md5sum pcp-jivelite_qvgaskins.tcz > pcp-jivelite_qvgaskins.tcz.md5.txt

rm -rf jivelite-build
rm hdskins.tar.gz
rm wqvgaskins.tar.gz
rm qvgaskins.tar.gz
