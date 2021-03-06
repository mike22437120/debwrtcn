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

OPENWRT_PATCHES_DIR=$(TOPDIR)/openwrt/patches

openwrt/all: openwrt/build
	$(MAKE) -C $(TOPDIR) openwrt/deliver

openwrt/build: openwrt/prepare
ifeq ("$(origin V)", "command line")
	$(SCRIPT_CLEAN_EXEC) $(MAKE) -C $(OPENWRT_BUILD_DIR) V=$(V)
else
	$(SCRIPT_CLEAN_EXEC) $(MAKE) -C $(OPENWRT_BUILD_DIR)
endif

openwrt/prepare: .config openwrt/checkout openwrt/patch openwrt/merge-config openwrt/download-link
	touch $@

openwrt/merge-config: $(TMP_DIR) openwrt/checkout openwrt/patch
	@# Copy default OpenWrt settings
	cp $(CONFIG_DIR)/openwrt.defconfig $(TMP_DIR)/.config_openwrt
	@# Merge default OpenWrt settings with menu settings
	cat .config | grep -v -e CONFIG_TARGET_BOARD -e "^#" >> $(TMP_DIR)/.config_openwrt
	@# Merge default and menu settings with possibly altered settings in make menuconfig in OpenWrt
	touch $(OPENWRT_BUILD_DIR)/.config
	cp $(OPENWRT_BUILD_DIR)/.config $(OPENWRT_BUILD_DIR)/.config.org
	@$(SCRIPT_KCONFIG) + $(OPENWRT_BUILD_DIR)/.config.org $(TMP_DIR)/.config_openwrt > $(OPENWRT_BUILD_DIR)/.config
	@# Make sure the config is clean
	$(SCRIPT_CLEAN_EXEC) $(MAKE) -C $(OPENWRT_BUILD_DIR) defconfig
	@# Copy DebWrt config to the build dir - used to set kernel compile options
	cp .config $(OPENWRT_BUILD_DIR)/.config.debwrt

openwrt/download-link: openwrt/checkout
	cd $(OPENWRT_BUILD_DIR) && if [ -d $(OPENWRT_DOWNLOAD_DIR) -a ! -e dl ]; then ln -snf $(OPENWRT_DOWNLOAD_DIR) dl; fi

openwrt/patch: openwrt/checkout
	patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/001_disable_all_openwrt_packages
ifeq ($(IS_OPENWRT_TRUNK),y)
	patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/trunk/002_install_kernel_modules_and_merge_debwrt_config
	patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/trunk/005_make_empty_rootfs
else ifeq ($(IS_OPENWRT_BACKFIRE),y)
	patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/backfire/002_install_kernel_modules_and_merge_debwrt_config
	patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/backfire/005_make_empty_rootfs
endif
	#patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/003_set_kernel_version
	patch -d $(OPENWRT_BUILD_DIR) -p 0 -N < $(PATCHES_DIR_OPENWRT)/004_save_environment_variables
	touch $@

openwrt/checkout:
	rm -rf $(OPENWRT_BUILD_DIR)
	mkdir -p $(OPENWRT_BUILD_DIR)
ifeq ($(IS_OPENWRT_TRUNK),y)
	cd $(OPENWRT_BUILD_DIR) && svn co svn://svn.openwrt.org/openwrt/trunk/ .
else ifeq ($(IS_OPENWRT_BACKFIRE),y)
	cd $(OPENWRT_BUILD_DIR) && svn co svn://svn.openwrt.org/openwrt/branches/backfire/ .
else
	cd $(OPENWRT_BUILD_DIR) && svn co -r $(OPENWRT_REVISION) svn://svn.openwrt.org/openwrt/trunk/ .
endif
	touch $@

openwrt/update: openwrt/checkout
ifeq ($(IS_OPENWRT_TRUNK),y)
	cd $(OPENWRT_BUILD_DIR) && svn update svn://svn.openwrt.org/openwrt/trunk/ .
else ifeq ($(IS_OPENWRT_BACKFIRE),y)
	cd $(OPENWRT_BUILD_DIR) && svn update svn://svn.openwrt.org/openwrt/branches/backfire/ .
else
	cd $(OPENWRT_BUILD_DIR) && svn update -r $(OPENWRT_REVISION) svn://svn.openwrt.org/openwrt/trunk/ .
endif

openwrt/menuconfig: openwrt/prepare
	$(SCRIPT_CLEAN_EXEC) $(MAKE) -C $(OPENWRT_BUILD_DIR) menuconfig

openwrt/clean:
	rm -rf $(OPENWRT_BUILD_DIR)
	rm -f openwrt/checkout
	rm -f openwrt/patch

