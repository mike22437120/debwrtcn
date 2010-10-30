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

TOPDIR:=${CURDIR}

all: world

include rules/functions.mk
include rules/scripts.mk
include rules/debwrt.mk
include rules/help.mk
include config/config.mk
include openwrt/openwrt.mk
include openwrt/openwrt-deliver.mk

world: .config openwrt/build
	@echo REVISION=$$REVISION
	@echo RELEASE=$$RELEASE
	@echo DEBWRTVERSION=$$DEBWRTVERSION
	@echo Make DebWrt

flash:
	cd $(INSTALL_DIR) && $(SCRIPT_FLASH) "$(call qstrip,$(CONFIG_FLASH_IP))" "$(TARGET_IMAGE_NAME)" || echo

clean: config-clean openwrt/clean
	@rm -f .config .config.old

FORCE: ;
.PHONY: FORCE
.NOTPARALLEL:


