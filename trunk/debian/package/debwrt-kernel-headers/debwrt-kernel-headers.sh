#!/bin/bash
#
# 1. Download package and unpack package
# 2. Copy debian/directory to it
# 3. Run dpkg-buildpackage --arch=<ARCH> -rfakeroot

export DEBFULLNAME="Amain (DebWrt.net)"
export LC_ALL=C
VERBOSE=1

[ "1" == $VERBOSE ] && set -x

export KERNEL_HEADERS_TAR_GZ=`ls debwrt-headers-*.tar.gz | sort | tail -1`

PACKAGE=debwrt-kernel-headers
VERSION=`echo $KERNEL_HEADERS_TAR_GZ | awk -F "-" '{print $6}'`
RELEASE=1

BASE_DIR=/usr/src
BUILD_BASE_DIR=${BASE_DIR}/${PACKAGE}
BUILD_DIR=${BUILD_BASE_DIR}/${PACKAGE}-${VERSION}
KCONF=${BUILD_BASE_DIR}/config-kernel-${VERSION}

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cp -ra ${KERNEL_HEADERS_TAR_GZ} ${BUILD_DIR}
cp -a ${KCONF} ${BUILD_DIR}/.config

if [ ! -d debian ]; then
   cd ${BUILD_DIR} 
   dh_make -c gpl -e "amain@debwrt.net" -s -n
   echo "Please complete debian package configuration. When done: cp -ra ${BUILD_DIR}/debian ."
else
   cp -rav debian ${BUILD_DIR}
   cd ${BUILD_DIR}
   dch -v ${VERSION}-${RELEASE} -m -t "Automated packet generation"
   dpkg-buildpackage -a${ARCH:=mipsel} -rfakeroot -b
   find ${BUILD_BASE_DIR} -maxdepth 1 -name "*.deb"  | xargs -r -t -i sudo dpkg-cross -a ${ARCH:=mipsel} -i {} || true
fi

