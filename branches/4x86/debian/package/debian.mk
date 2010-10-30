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

include $(TOPDIR)/debian/package/libnl/build.mk
include $(TOPDIR)/debian/package/iw/build.mk
include $(TOPDIR)/debian/package/debwrt-kernel-headers/build.mk
include $(TOPDIR)/debian/package/robocfg/build.mk
include $(TOPDIR)/debian/package/nvram/build.mk
include $(TOPDIR)/debian/package/hostapd/build.mk
include $(TOPDIR)/debian/package/shellinabox/build.mk
include $(TOPDIR)/debian/package/libpar2/build.mk
include $(TOPDIR)/debian/package/nzbget/build.mk

debian/package/rootfs: debian/package/iw          \
                       debian/package/libnl       \
                       debian/package/robocfg     \
                       debian/package/nvram       \
                       debian/package/hostapd     \
                       debian/package/shellinabox 
#                       debian/package/libpar2     \
#                       debian/package/nzbget

debian/package/clean:
	rm -rf $(DEBIAN_BUILD_DIR)/usr/src/*	
	rm -f $(TOPDIR)/debian/package/*/build
	rm -f $(TOPDIR)/debian/package/*/prepare
	rm -f $(TOPDIR)/debian/package/*/deliver
