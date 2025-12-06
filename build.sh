#!/bin/bash
downloader() {
if [ -f /usr/bin/curl ]; then
   curl -o $1 $2
elif [ -f /usr/bin/wget ]; then
   wget -O $1 $2
elif [ -f /usr/bin/python3 ]; then
   python3 <<EOF
import urllib.request
urllib.request.urlretrieve("$2", "$1")
EOF
elif [ -f /usr/bin/python2 ]; then
   python2 <<EOF
import urllib
urllib.urlretrieve("$2", "$1")
EOF
fi
}
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi
mkdir -p ${INSTX_TOPDIR}/build
downloader ${INSTX_TOPDIR}/build/build-$1.sh https://raw.githubusercontent.com/andykimpe1/Build-Scripts/refs/heads/build/build/build-$1.sh
chmod +x ${INSTX_TOPDIR}/*.sh
chmod +x ${INSTX_TOPDIR}/build/*.sh
${INSTX_TOPDIR}/build/build-$1.sh
