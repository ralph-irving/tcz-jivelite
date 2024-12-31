#!/bin/bash

image[1]=vu_analog_25seq_blue.png
tcz[1]=VU_Meter_Alex_Blue.tcz
image[2]=vu_analog_25seq_record.png
tcz[2]=VU_Meter_Alex_Record.tcz
image[3]=vu_analog_25seq_seg1.png
tcz[3]=VU_Meter_Alex_Segments1.tcz
image[4]=vu_analog_25seq_seg2.png
tcz[4]=VU_Meter_Alex_Segments2.tcz
image[5]=vu_analog_25seq_seg3.png
tcz[5]=VU_Meter_Alex_Segments3.tcz
image[6]=vu_analog_25seq_speaker.png
tcz[6]=VU_Meter_Alex_Speaker.tcz
image[7]=vu_analog_25seq_vfd.png
tcz[7]=VU_Meter_Alex_VFD.tcz
image[8]=vu_analog_25seq_seg4.png
tcz[8]=VU_Meter_Alex_Segments4.tcz
image[9]=vu_analog_25seq_led.png
tcz[9]=VU_Meter_Alex_LED.tcz
image[10]=vu_analog_25seq_speaker2.png
tcz[10]=VU_Meter_Alex_Speaker2.tcz
image[11]=vu_analog_25seq_speaker3.png
tcz[11]=VU_Meter_Alex_Speaker3.tcz

i=1
while true; do
    if [ -z ${image[$i]} ]; then
        break
    fi

    if [ -f ${tcz[$i]} ]; then
        rm ${tcz[$i]}
    fi
    
    if [ -d jivelite-build ]; then
        rm -rf jivelite-build
    fi

    mkdir -p jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter
    cp -p "Alex_VU_Meters/${image[$i]}" \
        jivelite-build/opt/jivelite/share/jive/applets/JogglerSkin/images/UNOFFICIAL/VUMeter/vu_analog_25seq_w.png

    mksquashfs jivelite-build ${tcz[$i]} -all-root -no-progress

    md5sum ${tcz[$i]} > "${tcz[$i]}.md5.txt"

    cd jivelite-build
    find * -not -type d > "../${tcz[$i]}.list"
    cd ..

    echo -e "Title:\t\t${tcz[$i]}" > "${tcz[$i]}.info"
    echo -e "Description:\tCommunity squeezebox controller 3rd party VU image." >> "${tcz[$i]}.info"
    echo -e "Version:\t8.0.0" >> "${tcz[$i]}.info"
    echo -e "Commit:\t\t$(git show | grep commit | awk '{print $2}')" >> "${tcz[$i]}.info"
    echo -e "Author:\t\tAlexander Aust" >> "${tcz[$i]}.info"
    echo -e "Original-site:\thttps://forums.slimdevices.com" >> "${tcz[$i]}.info"
    echo -e "Copying-policy:\tPublic Domain" >> "${tcz[$i]}.info"
    echo -e "Size:\t\t$(ls -lk ${tcz[$i]} | awk '{print $5}')" >> "${tcz[$i]}.info"
    echo -e "Extension_by:\tpiCorePlayer team: https://www.picoreplayer.org/" >> "${tcz[$i]}.info"
    echo -e "\t\tPackaged for piCore 15.x" >> "${tcz[$i]}.info"

    i=`expr ${i} + 1`
done

