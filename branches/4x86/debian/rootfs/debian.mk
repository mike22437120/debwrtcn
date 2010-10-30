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

DEBIAN_ROOTFS_INCLUDE_PACKAGES:=$(call qstrip,$(CONFIG_DEBIAN_ROOTFS_INCLUDE_PACKAGES))
DEBWRT_EXTRA_ROOTFS_FILES_DIR:=$(TOPDIR)/debian/rootfs/files
DEBWRT_MODULES_ARCHIVE=$(shell ls $(INSTALL_DIR)/debwrt-modules-*.tar.gz 2>/dev/null)
MODULES_VERSION=$(shell echo `basename $(DEBWRT_MODULES_ARCHIVE) 2>/dev/null` | awk -F '-' '{print $$6}')

debian/rootfs: debian/rootfs/bootstrap debian/rootfs/unpack debian/rootfs/files-install debian/rootfs/debwrt-packages debian/rootfs/modules-install debian/rootfs/post-setup
	touch $@

debian/rootfs/install: debian/rootfs
	if [ -d /media/DEBWRT_ROOT ]; then \
		sudo rm -rf /media/DEBWRT_ROOT/*; \
		sudo bash -c "tar cf - -C $(ROOTFS_BUILD_DIR) . | tar xf - -C /media/DEBWRT_ROOT"; \
	fi
	#touch $@

debian/rootfs/save:
	if [ -d /media/DEBWRT_ROOT ]; then \
		sudo bash -c "tar cjf debwrt-rootfs-$(TARGET_ARCH)-$(VERSION).tar.bz2 -C /media/DEBWRT_ROOT ."; \
	fi

debian/rootfs/files-install: debian/rootfs/bootstrap
	if [ ! -f $(ROOTFS_BUILD_DIR)/etc/init.d/rcS.debian -a -e $(ROOTFS_BUILD_DIR)/etc/init.d/rcS ]; then \
		sudo mv -v $(ROOTFS_BUILD_DIR)/etc/init.d/rcS $(ROOTFS_BUILD_DIR)/etc/init.d/rcS.debian; \
	fi
	if [ ! -f $(ROOTFS_BUILD_DIR)/dev/initctl ]; then  \
		sudo mkdir -p $(ROOTFS_BUILD_DIR)/dev;         \
		sudo mkfifo   $(ROOTFS_BUILD_DIR)/dev/initctl; \
	fi
	chmod 600 $(DEBWRT_EXTRA_ROOTFS_FILES_DIR)/etc/ssh/ssh_host_rsa_key
	chmod 600 $(DEBWRT_EXTRA_ROOTFS_FILES_DIR)/etc/ssh/ssh_host_dsa_key
	sudo bash -c "tar cf - --exclude=".svn" -C $(DEBWRT_EXTRA_ROOTFS_FILES_DIR) . | tar -xovf - -C $(ROOTFS_BUILD_DIR)"
	touch $@

debian/rootfs/modules-install: debian/rootfs/bootstrap
ifneq ($(DEBWRT_MODULES_ARCHIVE),)
	sudo tar xof $(DEBWRT_MODULES_ARCHIVE) -C $(ROOTFS_BUILD_DIR)
	#sudo depmod -a -b $(ROOTFS_BUILD_DIR) $(MODULES_VERSION)
endif
	touch $@

debian/rootfs/bootstrap: debian/rootfs/clean-rootfs-dir
	sudo debootstrap --arch=$(TARGET_ARCH)\
    	             --foreign \
        	         --include="$(DEBIAN_ROOTFS_INCLUDE_PACKAGES)" \
            	     $(DEBIAN_BUILD_VERSION) \
     	             $(ROOTFS_BUILD_DIR) \
    	             $(CONFIG_DEBIAN_BUILDENV_REPOSITORY)
	touch $@

debian/rootfs/unpack: debian/rootfs/bootstrap
	find $(ROOTFS_BUILD_DIR) -name "*.deb" | while read deb; do \
		n=`basename $$deb`; \
		echo -n "I: Extracting $${n}..."; \
		sudo bash -c "ar -p "$$deb" data.tar.gz | zcat | tar -C $(ROOTFS_BUILD_DIR) -xf -"; \
		echo "done"; \
	done
	touch $@

# install all available cross-compiled debwrt debian packages, extect for the kernel-headers packages because it is to big
debian/rootfs/debwrt-packages: debian/rootfs/bootstrap debian/package/rootfs
	ls ${INSTALL_DIR_DEBIAN_PACKAGES}/*.deb | grep -v "debwrt-kernel-headers" | while read package; do \
		pfname=`basename $$package`; \
		pname=`echo $$pfname | sed 's/_.*//'`; \
		echo "Installing DebWrt package: $$pname"; \
		sudo cp $$package $(ROOTFS_BUILD_DIR)/var/cache/apt/archives; \
		sudo dpkg-deb -x $$package $(ROOTFS_BUILD_DIR); \
		sudo bash -c "echo \"$$pname /var/cache/apt/archives/$$pfname\" >>$(ROOTFS_BUILD_DIR)/debootstrap/debpaths" ;\
	done
	touch $@
	
debian/rootfs/clean-rootfs-dir:
	sudo rm -rf $(ROOTFS_BUILD_DIR)
	touch $@

debian/rootfs/post-setup: debian/rootfs/bootstrap
	sudo mkdir -p $(ROOTFS_BUILD_DIR)/etc/apt
	sudo bash -c "echo \"deb http://ftp.debian.org/debian $(DEBIAN_BUILD_VERSION) main\" >$(ROOTFS_BUILD_DIR)/etc/apt/sources.list"
	touch $@

debian/rootfs/clean: 
	sudo rm -rf $(ROOTFS_BUILD_DIR)
	rm -f debian/rootfs/debwrt-packages
	rm -f debian/rootfs/bootstrap
	rm -f debian/rootfs/install
	rm -f debian/rootfs/files-install
	rm -f debian/rootfs/modules-install

