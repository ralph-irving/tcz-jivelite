#!/bin/bash
ARCH=$(uname -m)
case "$ARCH" in
        aarch64)
                PLATFORM=pcp9-64
                ;;
        *)
                PLATFORM=pcp9
                ;;
esac

VERSION=$(awk -F\" '{printf "%s", $2}' jivelite/src/version.h)

if [ -z "$VERSION" ]; then
	VERSION=unknown
fi

tar -czf pcp-jivelite-${VERSION}-${PLATFORM}.tar.gz pcp-jivelite.tcz pcp-jivelite.tcz.dep pcp-jivelite.tcz.info pcp-jivelite.tcz.list pcp-jivelite.tcz.md5.txt pcp-jivelite_hdskins.tcz pcp-jivelite_hdskins.tcz.info pcp-jivelite_hdskins.tcz.list pcp-jivelite_hdskins.tcz.md5.txt pcp-jivelite_qvgaskins.tcz pcp-jivelite_qvgaskins.tcz.info pcp-jivelite_qvgaskins.tcz.list pcp-jivelite_qvgaskins.tcz.md5.txt pcp-jivelite_wqvgaskins.tcz pcp-jivelite_wqvgaskins.tcz.info pcp-jivelite_wqvgaskins.tcz.list pcp-jivelite_wqvgaskins.tcz.md5.txt VU_Meter_* pcp-lua.tcz pcp-lua.tcz.dep pcp-lua.tcz.info pcp-lua.tcz.list pcp-lua.tcz.md5.txt

