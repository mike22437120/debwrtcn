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

# The following function imports some environment variables
# save in a special config file during OpenWrt's build process
#
# OPENWRT_BIN_DIR		- directory where OpenWrt firmware is stored
# OPENWRT_PACKAGE_DIR	- directory where OpenWrt packages are stored
# OPENWRT_TMP_DIR		- directory where OpenWrt stored all kernel modules
# OPENWRT_LINUX_VERSION	- kernel version of the kernel build by OpenWrt
# OPENWRT_LINUX_DIR     - OpenWrt's kernel build directory
#
-include $(OPENWRT_SAVE_CONFIG_FILE)

ERROR_MSG_NOCONF:=" not defined. Make sure OpenWrt build finished."

openwrt/deliver: openwrt/deliver/prepare        openwrt/deliver/clean 			\
				 openwrt/deliver/image 	        openwrt/deliver/kernel-modules	\
				 openwrt/deliver/packages       openwrt/deliver/config		    \
				 openwrt/deliver/kernel-headers

openwrt/deliver/prepare: openwrt/deliver/import-config openwrt/deliver/check

openwrt/deliver/import-config:
	@echo OPENWRT_BIN_DIR=$(OPENWRT_BIN_DIR)
	@echo OPENWRT_PACKAGE_DIR=$(OPENWRT_PACKAGE_DIR)
	@echo OPENWRT_TMP_DIR=$(OPENWRT_TMP_DIR)
	@echo OPENWRT_LINUX_VERSION=$(OPENWRT_LINUX_VERSION)
	@echo OPENWRT_LINUX_DIR=$(OPENWRT_LINUX_DIR)

openwrt/deliver/check: ${OPENWRT_BIN_DIR} openwrt/deliver/import-config
  ifndef OPENWRT_PACKAGE_DIR
	@echo OPENWRT_PACKAGE_DIR$(ERROR_MSG_NOCONF) && false
  endif
  ifndef OPENWRT_TMP_DIR
	@echo OPENWRT_TMP_DIR$(ERROR_MSG_NOCONF) && false
  endif
  ifndef OPENWRT_LINUX_VERSION
	@echo OPENWRT_LINUX_VERSION$(ERROR_MSG_NOCONF) && false
  endif
  ifndef OPENWRT_LINUX_DIR
	@echo OPENWRT_LINUX_DIR$(ERROR_MSG_NOCONF) && false
  endif
  ifndef OPENWRT_PACKAGE_DIR
	@echo OPENWRT_PACKAGE_DIR$(ERROR_MSG_NOCONF) && false
  endif

openwrt/deliver/image: openwrt/deliver/prepare
	mkdir -p $(INSTALL_DIR)
	if  [ "unknown" != $(call qstrip,$(CONFIG_OPENWRT_TARGET_IMAGE_NAME_BIN)) ]; then \
		cp -a ${OPENWRT_BIN_DIR}/$(call qstrip,$(CONFIG_OPENWRT_TARGET_IMAGE_NAME_BIN)) $(INSTALL_DIR)/$(TARGET_IMAGE_NAME_BIN); \
	else  \
		echo "Failed to copy firmware BIN image. Configure image name in config/image_name.in"; \
	fi
	if  [ "unknown" != $(call qstrip,$(CONFIG_OPENWRT_TARGET_IMAGE_NAME_TRX)) ]; then \
		cp -a ${OPENWRT_BIN_DIR}/$(call qstrip,$(CONFIG_OPENWRT_TARGET_IMAGE_NAME_TRX)) $(INSTALL_DIR)/$(TARGET_IMAGE_NAME_TRX); \
	else  \
		echo "Failed to copy firmware TRX image. Configure image name in config/image_name.in"; \
	fi
	if [ ! -e $(INSTALL_DIR)/$(TARGET_IMAGE_NAME_BIN) -a ! -e $(INSTALL_DIR)/$(TARGET_IMAGE_NAME_TRX) ]; then \
		echo "Failed to copy a firmware image. Investigate." && false; \
	fi

openwrt/deliver/kernel-modules: openwrt/deliver/prepare
	mkdir -p $(INSTALL_DIR) $(INSTALL_DIR_OPENWRT) $(INSTALL_DIR_OPENWRT_MODULES)
	mkdir -p $(INSTALL_DIR_OPENWRT_MODULES)/lib/modules
	cp -r ${OPENWRT_TMP_DIR}/modules/lib/modules/${OPENWRT_LINUX_VERSION} $(INSTALL_DIR_OPENWRT_MODULES)/lib/modules
	rm -f $(INSTALL_DIR_OPENWRT_MODULES)/lib/modules/${OPENWRT_LINUX_VERSION}/build
	rm -f $(INSTALL_DIR_OPENWRT_MODULES)/lib/modules/${OPENWRT_LINUX_VERSION}/source
	find $(OPENWRT_PACKAGE_DIR) -name "kmod-*" | while read fkmod; do \
	    $(SCRIPT_EXTRACT_KMODPKG) $$fkmod $(INSTALL_DIR_OPENWRT_MODULES) $(TMP_DIR) || true; \
	done
	depmod -a -b $(INSTALL_DIR_OPENWRT_MODULES) ${OPENWRT_LINUX_VERSION}
	tar czf $(INSTALL_DIR)/$(MODULES_TAR_GZ) -C $(INSTALL_DIR_OPENWRT_MODULES) .

openwrt/deliver/kernel-headers: openwrt/deliver/prepare
	mkdir -p $(INSTALL_DIR_OPENWRT_HEADERS)
	mkdir -p $(INSTALL_DIR_OPENWRT_HEADERS)/usr/src/${OPENWRT_LINUX_VERSION}
	cd $(OPENWRT_LINUX_DIR)
	find . -path './include/*' -prune \
		-o -path './scripts/*' -prune -o -type f \
		\( -name 'Makefile*' -o -name 'Kconfig*' -o -name 'Kbuild*' -o \
		-name '*.sh' -o -name '*.pl' -o -name '*.lds' \) \
		-print | cpio -pd --preserve-modification-time 
	cp -a drivers/media/dvb/dvb-core/*.h $(INSTALL_DIR_OPENWRT_HEADERS)/usr/src/${OPENWRT_LINUX_VERSION}/drivers/media/dvb/dvb-core
	cp -a drivers/media/video/*.h $(INSTALL_DIR_OPENWRT_HEADERS)/usr/src/${OPENWRT_LINUX_VERSION}/drivers/media/video
	cp -a drivers/media/dvb/frontends/*.h $(INSTALL_DIR_OPENWRT_HEADERS)/usr/src/${OPENWRT_LINUX_VERSION}/drivers/media/dvb/frontends
	cp -a scripts include $(INSTALL_DIR_OPENWRT_HEADERS)/usr/src/${OPENWRT_LINUX_VERSION}
	(find arch -name include -type d -print | \
		xargs -n1 -i: find : -type f) | \
		cpio -pd --preserve-modification-time $(INSTALL_DIR_OPENWRT_HEADERS)/usr/src/${OPENWRT_LINUX_VERSION}

openwrt/deliver/packages: openwrt/deliver/prepare
	mkdir -p $(INSTALL_DIR_OPENWRT_PACKAGES)
	cp -ra $(OPENWRT_PACKAGE_DIR)/* $(INSTALL_DIR_OPENWRT_PACKAGES)

openwrt/deliver/config: openwrt/deliver/prepare
	cp ${TOPDIR}/.config $(INSTALL_DIR)/config-debwrt
	cp ${OPENWRT_BUILD_DIR}/.config $(INSTALL_DIR)/config-openwrt
	cp ${OPENWRT_LINUX_DIR}/.config $(INSTALL_DIR)/config-kernel-${OPENWRT_LINUX_VERSION}

openwrt/deliver/clean:
	rm -rf $(INSTALL_DIR)

