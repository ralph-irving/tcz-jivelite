# tcz-jivelite
piCoPlayer /dev/fb jivelite.tcz

Installation Instructions on piCorePlayer 1.19+

Copy these two files to /mnt/mmcblk0p2/tce/optional on the piCorePlayer sd card.

You might need to increase the size of the ext4 partition mmcblk0p2 depending on your free space.

https://github.com/ralph-irving/tcz-jivelite/raw/master/jivelite.tcz

https://github.com/ralph-irving/tcz-jivelite/raw/master/jivelite.tcz.md5.txt


Add the following line to the end of /mnt/mmcblk0p2/tce/onboot.lst

jivelite.tcz


To start jivelite on boot add this line in one of the user command fields at the bottom of the tweaks webgui.

/opt/jivelite/bin/jivelite-sp


I've tested it on a B and B+.

You need a keyboard to configure jivelite inititally and either a composite or hdmi monitor connected.

Here's the key map http://wiki.slimdevices.com/index.ph...Developers_FAQ

It also works with a mouse or touchpad and should work with touch screens as well, if the screen uses the framebuffer devices like /dev/fb?.

You can also use it with a flirc IR dongle and a squeezebox remote.

https://flirc.tv/product/flirc/

You'll need to load one of the flirc config from another computer.  Start with the fcfg in ralphy_jivelite_flirc_map.zip first and if you get multiple key presses for one press then try the other config in ralphy_jivelite_flirc_map_debounce.zip

Both files are available in the repository.

Not all the keys on the slimremote map 1-to-1, here are the exceptions.

Sleep = Escape/Back

Power = Power (Only from Now Playing screen)

Favorites = Favorites

Search = Current Track Info

Browse = Music Library

Now Playing = Now Playing

Size = Stop

Brightness = Playlists 


Build instructions to recreate jivelite.tcz from scratch on raspbian 7.8.

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

tar -C /opt/squeezeplay ../build/squeezeplay-7.8.0-.tgz


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

