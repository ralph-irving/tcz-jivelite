#!/bin/bash

if [ -z $1 ]; then
	echo "Need to specify a release number. For example 10"
	exit 1
fi

REVISION=unknown

if [ ! -f jivelite/src/version.h ]; then
	echo "Jivelite version.h not found. Revision unknown."
else
	REVISION=$(awk -F\" '{printf "%s", $2}' jivelite/src/version.h)
fi


ARCH=$(uname -m)
case "$ARCH" in
        aarch64)
                PLATFORM=pcp${1}-64
                ;;
        *)
                PLATFORM=pcp${1}
                ;;
esac

tar -czf pcp-jivelite-${REVISION}-${PLATFORM}.tar.gz pcp-jivelite.tcz pcp-jivelite.tcz.dep pcp-jivelite.tcz.info pcp-jivelite.tcz.list pcp-jivelite.tcz.md5.txt pcp-jivelite_hdskins.tcz pcp-jivelite_hdskins.tcz.info pcp-jivelite_hdskins.tcz.list pcp-jivelite_hdskins.tcz.md5.txt pcp-jivelite_qvgaskins.tcz pcp-jivelite_qvgaskins.tcz.info pcp-jivelite_qvgaskins.tcz.list pcp-jivelite_qvgaskins.tcz.md5.txt pcp-jivelite_wqvgaskins.tcz pcp-jivelite_wqvgaskins.tcz.info pcp-jivelite_wqvgaskins.tcz.list pcp-jivelite_wqvgaskins.tcz.md5.txt VU_Meter_* pcp-lua.tcz pcp-lua.tcz.dep pcp-lua.tcz.info pcp-lua.tcz.list pcp-lua.tcz.md5.txt

