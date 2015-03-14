# tcz-jivelite
piCorePlayer /dev/fb jivelite.tcz

**Installation Instructions on piCorePlayer 1.19+**

Copy these two files to /mnt/mmcblk0p2/tce/optional on the piCorePlayer sd card.  There's enough free space on the default image to add the jivelite files.  If you've installed other packages you might need to increase the size of the ext4 partition mmcblk0p2.

https://github.com/ralph-irving/tcz-jivelite/raw/master/jivelite.tcz

https://github.com/ralph-irving/tcz-jivelite/raw/master/jivelite.tcz.md5.txt

Add the following line to the end of /mnt/mmcblk0p2/tce/onboot.lst

jivelite.tcz

To start jivelite on boot add this line in one of the user command fields at the bottom of the tweaks webgui.

/opt/jivelite/bin/jivelite-sp

To enable the visualizer now playing screens in 1.19, add a lowercase -v to the Various Input text field at the bottom of the Squeezelite Settings webgui page as the Visualiser support option is broken in 1.19.

Reboot piCorePlayer

To enable visualizers support after having run the jivelite config once already, add -v as above, kill the jivelite process, then delete the .jivelite folder in /home/tc and reboot.  After the reboot you will need to reconfigure jivelte.

The jivelite package is currently being evaluated for inclusion in the default piCorePlayer image.

I've tested it on a B and B+.

You need a keyboard to configure jivelite initially and either a composite or hdmi monitor connected.

Here's the key map http://wiki.slimdevices.com/index.php/SqueezePlay_Developers_FAQ

Only the Joggler and WQVGA Small Print Skins work with a mouse or touchpad and should work with touch screens, if the screen uses a framebuffer device like /dev/fb?.

Note that NONE of the HD Skins support a pointer or touch device.

All the skins can be used with a flirc IR dongle and a squeezebox remote.

https://flirc.tv/product/flirc/

You'll need to load one of the flirc config files from another computer.  Start with the fcfg file in **ralphy_jivelite_flirc_map.zip** and if you get multiple key presses for one press then try the other config in **ralphy_jivelite_flirc_map_debounce.zip**

Both files are available in the repository.

Not all the keys on the slimremote map 1-to-1, here are the exceptions.

Sleep = Escape/Back

Power = Power (Only from Now Playing screen)

Search = Current Track Info

Browse = Music Library

Size = Stop

Brightness = Playlists 


**Build instructions to recreate jivelite.tcz from scratch on raspbian 7.8.**

Compile squeezeplay

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

tar -C /opt/squeezeplay -xzf ../build/squeezeplay-7.8.0-.tgz


Compile jivelite

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

