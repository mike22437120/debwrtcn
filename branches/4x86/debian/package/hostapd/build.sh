#!/bin/bash
#
# 1. Download package and unpack package
# 2. Copy debian/directory to it
# 3. Run dpkg-buildpackage --arch=<ARCH> -rfakeroot

if [ -z $ARCH ]; then echo "First set \$ARCH before running the build script"; exit 1; fi

export DEBFULLNAME="Amain (DebWrt.net)"
export LC_ALL=C
VERBOSE=1

[ "1" == $VERBOSE ] && set -x

PACKAGE=hostapd
VERSION=1.0
RELEASE=1
DOWNLOAD_URL=svn://svn.openwrt.org/openwrt/trunk/package/${PACKAGE}
DEP=

BASE_DIR=/usr/src
BUILD_BASE_DIR=${BASE_DIR}/${PACKAGE}
BUILD_DIR=${BUILD_BASE_DIR}/${PACKAGE}-${VERSION}
DOWNLOAD_DIR=${BASE_DIR}/dl

mkdir -p $DOWNLOAD_DIR
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
svn co ${DOWNLOAD_URL} ${BUILD_DIR}

VERSION=`cat ${BUILD_DIR}/Makefile  | grep ^PKG_VERSION | awk -F ":=" '{print $2}'`
OPENWRT_VERSION=${VERSION:=20100705}
PACKAGE_SOURCE=hostapd-${OPENWRT_VERSION}.tar.bz2
DOWNLOAD_URL2=http://mirror2.openwrt.org/sources/hostapd-${OPENWRT_VERSION}.tar.bz2

if [ ! -s ${DOWNLOAD_DIR}/${PACKAGE_SOURCE} ]; then rm -f ${DOWNLOAD_DIR}/${PACKAGE_SOURCE}; wget -O ${DOWNLOAD_DIR}/${PACKAGE_SOURCE} $DOWNLOAD_URL2; fi
mkdir -p ${BUILD_DIR}/src
tar xjf ${DOWNLOAD_DIR}/${PACKAGE_SOURCE} -C ${BUILD_DIR}/src --strip 1

# apply openwrt patches
for patch in `ls ${BUILD_DIR}/patches | sort`; do
    patch -d ${BUILD_DIR}/src -p1 <${BUILD_DIR}/patches/$patch
done

# download madwifi from openwrt, to determine which madwifi version to use
DOWNLOAD_URL3=svn://svn.openwrt.org/openwrt/trunk/package/madwifi
mkdir -p ${BUILD_DIR}/src/madwifi
svn co ${DOWNLOAD_URL3} ${BUILD_DIR}/src/madwifi

# download correct version from madwifi
REV=`cat ${BUILD_DIR}/src/madwifi/Makefile  | grep ^PKG_REV | awk -F ":=" '{print $2}'`
OPENWRT_VERSION="r${REV:=3314}"
PACKAGE_SOURCE=madwifi-trunk-${OPENWRT_VERSION}.tar.gz
DOWNLOAD_URL4=http://mirror2.openwrt.org/sources/${PACKAGE_SOURCE}

if [ ! -s ${DOWNLOAD_DIR}/${PACKAGE_SOURCE} ]; then rm -f ${DOWNLOAD_DIR}/${PACKAGE_SOURCE}; wget -O ${DOWNLOAD_DIR}/${PACKAGE_SOURCE} $DOWNLOAD_URL4; fi
tar xzf ${DOWNLOAD_DIR}/${PACKAGE_SOURCE} -C ${BUILD_DIR}/src/madwifi --strip 1

# cp config file
cp ${BUILD_DIR}/files/hostapd-mini.config ${BUILD_DIR}/src/hostapd/.config

# make sure it compiles
echo "CONFIG_INTERNAL_LIBTOMMATH=internal" >>${BUILD_DIR}/src/hostapd/.config

# temporary remove madwifi
#sed -i '/CONFIG_DRIVER_MADWIFI/d' ${BUILD_DIR}/src/hostapd/.config

if [ ! -d debian ]; then
   cd ${BUILD_DIR} 
   dh_make -c gpl -e "amain@debwrt.net" -s -n
   echo "Please complete debian package configuration. And copy the files back to the svn working directory."
   exit 1
else
   cp -rav debian ${BUILD_DIR}
   cd ${BUILD_DIR}
   dpkg-buildpackage -a${ARCH} -rfakeroot
   find ${BUILD_BASE_DIR} -maxdepth 1 -name "*.deb"  | xargs -r -t -i sudo dpkg-cross -a ${ARCH} -i {} || true
fi

