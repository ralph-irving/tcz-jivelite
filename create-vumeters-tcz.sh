#!/bin/bash

# VU_Meter_Jstraw_Dark_Peak.tcz (e)

if [ -f VU_Meter_Jstraw_Dark_Peak.tcz ]; then
	rm VU_Meter_Jstraw_Dark_Peak.tcz
fi

# VU_Meter_Jstraw_Dark.tcz (d)

if [ -f VU_Meter_Jstraw_Dark.tcz ]; then
	rm VU_Meter_Jstraw_Dark.tcz
fi

# VU_Meter_Jstraw_Vintage.tcz (j)

if [ -f VU_Meter_Jstraw_Vintage.tcz ]; then
	rm VU_Meter_Jstraw_Vintage.tcz
fi

# VU_Meter_Kolossos_Oval.tcz (k)

if [ -f VU_Meter_Kolossos_Oval.tcz ]; then
	rm VU_Meter_Kolossos_Oval.tcz
fi

# VU_Meter_Logitech_Black.tcz (b)

if [ -f VU_Meter_Logitech_Black.tcz ]; then
	rm VU_Meter_Logitech_Black.tcz
fi

# VU_Meter_Logitech_White.tcz (w)

if [ -f VU_Meter_Logitech_White.tcz ]; then
	rm VU_Meter_Logitech_White.tcz
fi


if [ -d jivelite-build ]; then
	rm -rf jivelite-build
fi

mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
cp -p jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png \
	jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter

mksquashfs jivelite-build VU_Meter_Logitech_White.tcz -all-root -no-progress
md5sum VU_Meter_Logitech_White.tcz > VU_Meter_Logitech_White.tcz.md5.txt
cd jivelite-build
find * -not -type d > ../VU_Meter_Logitech_White.tcz.list
cd ..

if [ -d jivelite-build ]; then
	rm -rf jivelite-build
else
	exit
fi

mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
cp -p jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_b.png \
	jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png

mksquashfs jivelite-build VU_Meter_Logitech_Black.tcz -all-root -no-progress
md5sum VU_Meter_Logitech_Black.tcz > VU_Meter_Logitech_Black.tcz.md5.txt
cd jivelite-build
find * -not -type d > ../VU_Meter_Logitech_Black.tcz.list
cd ..

if [ -d jivelite-build ]; then
	rm -rf jivelite-build
else
	exit
fi

mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
cp -p vu_analog_25seq_k.png \
	jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png

mksquashfs jivelite-build VU_Meter_Kolossos_Oval.tcz -all-root -no-progress
md5sum VU_Meter_Kolossos_Oval.tcz > VU_Meter_Kolossos_Oval.tcz.md5.txt
cd jivelite-build
find * -not -type d > ../VU_Meter_Kolossos_Oval.tcz.list
cd ..

if [ -d jivelite-build ]; then
	rm -rf jivelite-build
else
	exit
fi

mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
cp -p jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_j.png \
	jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png

mksquashfs jivelite-build VU_Meter_Jstraw_Vintage.tcz -all-root -no-progress
md5sum VU_Meter_Jstraw_Vintage.tcz > VU_Meter_Jstraw_Vintage.tcz.md5.txt
cd jivelite-build
find * -not -type d > ../VU_Meter_Jstraw_Vintage.tcz.list
cd ..

if [ -d jivelite-build ]; then
	rm -rf jivelite-build
else
	exit
fi

mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
cp -p jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_d.png \
	jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png

mksquashfs jivelite-build VU_Meter_Jstraw_Dark.tcz -all-root -no-progress
md5sum VU_Meter_Jstraw_Dark.tcz > VU_Meter_Jstraw_Dark.tcz.md5.txt
cd jivelite-build
find * -not -type d > ../VU_Meter_Jstraw_Dark.tcz.list
cd ..

if [ -d jivelite-build ]; then
	rm -rf jivelite-build
else
	exit
fi

mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
cp -p jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_e.png \
	jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png

mksquashfs jivelite-build VU_Meter_Jstraw_Dark_Peak.tcz -all-root -no-progress
md5sum VU_Meter_Jstraw_Dark_Peak.tcz > VU_Meter_Jstraw_Dark_Peak.tcz.md5.txt
cd jivelite-build
find * -not -type d > ../VU_Meter_Jstraw_Dark_Peak.tcz.list
cd ..

