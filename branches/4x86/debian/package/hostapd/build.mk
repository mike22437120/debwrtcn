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

debian/package/hostapd: debian/package/hostapd/deliver
	touch $@

debian/package/hostapd/deliver: debian/package/hostapd/build
	mkdir -p ${INSTALL_DIR_DEBIAN_PACKAGES}
	cp -rav $(DEBIAN_BUILD_DIR)/usr/src/hostapd/*.deb ${INSTALL_DIR_DEBIAN_PACKAGES}
	cp -rav $(DEBIAN_BUILD_DIR)/usr/src/hostapd/*.tar.gz ${INSTALL_DIR_DEBIAN_PACKAGES}
	cp -rav $(DEBIAN_BUILD_DIR)/usr/src/hostapd/*.dsc ${INSTALL_DIR_DEBIAN_PACKAGES}
	cp -rav $(DEBIAN_BUILD_DIR)/usr/src/hostapd/*.changes ${INSTALL_DIR_DEBIAN_PACKAGES}
	touch $@

debian/package/hostapd/build: debian/package/hostapd/prepare debian/package/libnl
	$(CHROOT_USER) bash -c "cd /usr/src/hostapd; export ARCH=$(TARGET_ARCH); ./build.sh"
	touch $@

debian/package/hostapd/prepare: debian/buildenv/create
	rm -rf   $(DEBIAN_BUILD_DIR)/usr/src/hostapd
	mkdir -p $(DEBIAN_BUILD_DIR)/usr/src/hostapd
	if [ -d $(DEBIAN_PACKAGES_DIR)/hostapd/debian ]; then \
	    cp -ar $(DEBIAN_PACKAGES_DIR)/hostapd/debian $(DEBIAN_BUILD_DIR)/usr/src/hostapd; \
	fi
	cp -ar $(DEBIAN_PACKAGES_DIR)/hostapd/build.sh $(DEBIAN_BUILD_DIR)/usr/src/hostapd
	touch $@

debian/package/hostapd/clean:
	rm -f debian/package/hostapd/build
	rm -f debian/package/hostapd/prepare
	rm -f debian/package/hostapd/deliver

