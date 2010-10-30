# DebWrt - Debian on Embedded devices
#
# Copyright (C) 2010 Johan van Zoomeren <amain@debwrt.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

RELEASE:=angel
BUILD_CYCLE_ID:=-1
VERSION:=1.0$(BUILD_CYCLE_ID)
RELEASE_DATE=$(shell LC_ALL=c date +"%d %B %Y")
SVN_REVISION:=$(shell $(SCRIPT_GET_SVN_REVISION))
DEBWRTVERSION:=$(RELEASE) - $(VERSION) - [ $(RELEASE_DATE) ($(SVN_REVISION)) ]
DEBWRT_VERSION:=$(RELEASE)-$(VERSION)

empty:=
space:= $(empty) $(empty)

# Include DebWrt config
-include $(TOPDIR)/.config

# Board [example: ar7xx]
BOARD:=$(call qstrip,$(CONFIG_TARGET_BOARD))

# Sub board [example: ubnt-rspro]
SUB_BOARD:=$(call qstrip,$(CONFIG_TARGET_SUB_BOARD))

# Linux version [2.6.X(.X)]
LINUX_VERSION:=$(call qstrip,$(CONFIG_DEBWRT_KERNEL_VERSION))

# OpenWrt Revision to checkout [rXXXX]
OPENWRT_REVISION:=$(call qstrip,$(CONFIG_OPENWRT_REVISION))

# OpenWrt Revision is trunk [y or emtpy]
IS_OPENWRT_TRUNK:=$(call qstrip,$(CONFIG_OPENWRT_REVISION_TRUNK))

# Base BuildDir
BUILD_DIR_BASE:=$(TOPDIR)/build

# Config dir
CONFIG_DIR:=$(TOPDIR)/config

# bin/delivery dir
BIN_DIR:=$(TOPDIR)/bin

# tmp dir
TMP_DIR:=$(TOPDIR)/tmp

# Install dir
INSTALL_DIR:=$(BIN_DIR)/$(BOARD)-$(DEBWRT_VERSION)-$(LINUX_VERSION)

# Install dir for OpenWrt binaries
INSTALL_DIR_OPENWRT:=$(INSTALL_DIR)/openwrt

# Install dir OpenWrt kernel modules
INSTALL_DIR_OPENWRT_MODULES:=$(INSTALL_DIR_OPENWRT)/modules

# Install dir OpenWrt packages
INSTALL_DIR_OPENWRT_PACKAGES:=$(INSTALL_DIR_OPENWRT)/packages

# Install dic OpenWrt kernel headers
INSTALL_DIR_OPENWRT_HEADERS:=$(INSTALL_DIR_OPENWRT)/headers

# Image file containing OpenWrt kernel modules
MODULES_TAR_GZ=debwrt-modules-${BOARD}-${SUB_BOARD}-${OPENWRT_LINUX_VERSION}-$(DEBWRT_VERSION).tar.gz

# Image file containing OpenWrt kernel headers
HEADERS_TAR_GZ=debwrt-headers-${BOARD}-${SUB_BOARD}-${OPENWRT_LINUX_VERSION}-$(DEBWRT_VERSION).tar.gz

# Filename of DebWrt firmware image
TARGET_IMAGE_NAME_BIN=debwrt-firmware-${BOARD}-${SUB_BOARD}-${OPENWRT_LINUX_VERSION}-$(DEBWRT_VERSION).bin
TARGET_IMAGE_NAME_TRX=debwrt-firmware-${BOARD}-${SUB_BOARD}-${OPENWRT_LINUX_VERSION}-$(DEBWRT_VERSION).trx

# OpenWrt patches directory
PATCHES_DIR_OPENWRT=$(TOPDIR)/openwrt/patches

# OpenWrt Build (checkout) directory
OPENWRT_BUILD_DIR:=$(BUILD_DIR_BASE)/openwrt-$(BOARD)-$(SUB_BOARD)-$(OPENWRT_REVISION)-$(LINUX_VERSION)

# Special saved environment variables during OpenWrt's build process
OPENWRT_SAVE_CONFIG_FILE:=$(OPENWRT_BUILD_DIR)/.openwrt_env

# Alternate OpenWrt download directory
OPENWRT_DOWNLOAD_DIR:=$(call qstrip,$(CONFIG_OPENWRT_DOWNLOAD_DIR))

# Debian build environment version
DEBIAN_BUILD_VERSION:=sid

# Debian
DEBIAN_BUILD_DIR:=$(BUILD_DIR_BASE)/debian-$(BOARD)-$(SUB_BOARD)-$(DEBIAN_BUILD_VERSION)


# Export defaults to other Makefiles
export

$(TMP_DIR) $(BIN_DIR) $(OPENWRT_BUILD_DIR) $(BUILD_DIR_BASE) $(INSTALL_DIR_BASE) $(INSTALL_DIR_OPENWRT) $(INSTALL_DIR_DEBIAN):
	mkdir -p $@

