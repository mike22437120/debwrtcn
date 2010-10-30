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
						#--include=$(subst $(space),$(empty),$(DEBIAN_BUILDENV_INCLUDE_PACKAGES))

debian/buildenv-create: debian/buildenv-prepare debian/qemu-build debian/scratchbox-prepare

debian/buildenv-prepare:
	mkdir -p $(DEBIAN_BUILD_DIR)
	# Due to various bugs in debootstrap in combination with fakechroot it is not 
	# possible to create a fakechroot here
	#fakeroot fakechroot debootstrap 
						#--variant=fakechroot 
	sudo debootstrap    --include=$(subst $(space),$(empty),$(CONFIG_DEBIAN_BUILDENV_INCLUDE_PACKAGES)) \
					    $(DEBIAN_BUILD_VERSION) \
						$(DEBIAN_BUILD_DIR) \
						$(CONFIG_DEBIAN_BUILDENV_REPOSITORY)
	sudo bash -c "echo \"deb http://www.emdebian.org/debian/ lenny main\" >> $(DEBIAN_BUILD_DIR)/etc/apt/sources.list"
	sudo bash -c "echo debwrt > $(DEBIAN_BUILD_DIR)/etc/debian_chroot"
	sudo bash -c "echo 0 > /proc/sys/vm/mmap_min_addr" # for ARM targets
	sudo chroot $(DEBIAN_BUILD_DIR) apt-get update
	sudo chroot $(DEBIAN_BUILD_DIR) apt-get -y --force-yes \
											install g++-4.3-mips-linux-gnu libc6-dev-mips-cross \
											   	    build-essential debootstrap fakeroot \
											        zlib1g-dev qemu-user scratchbox2
	sudo chroot $(DEBIAN_BUILD_DIR) groupadd debwrt
	sudo chroot $(DEBIAN_BUILD_DIR) useradd -g debwrt -s /bin/bash -m $$USER
	touch $@

debian/qemu-prepare:
	sudo chroot $(DEBIAN_BUILD_DIR) bash -c "cd /usr/src && wget http://download.savannah.gnu.org/releases/qemu/qemu-$(call qstrip,$(CONFIG_DEBIAN_BUILDENV_QEMU_VERSION)).tar.gz && tar xzf qemu-$(call qstrip,$(CONFIG_DEBIAN_BUILDENV_QEMU_VERSION)).tar.gz"
	touch $@

debian/qemu-build: debian/qemu-prepare
	sudo chroot $(DEBIAN_BUILD_DIR) bash -c "cd /usr/src/qemu-$(call qstrip,$(CONFIG_DEBIAN_BUILDENV_QEMU_VERSION)) && ./configure --target-list=mips-linux-user && make && make install"
	touch $@

debian/scratchbox-prepare:
	sudo chroot $(DEBIAN_BUILD_DIR) bash -c "mkdir -p /targets/mips-lenny && chown $(USER):debwrt /targets/mips-lenny"
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd /targets/mips-lenny && sb2-init -c /usr/local/bin/qemu-mips MIPS \"mips-linux-gnu-gcc\""
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "fakeroot /usr/sbin/debootstrap --variant=scratchbox --foreign --arch mips lenny /targets/mips-lenny/ $(CONFIG_DEBIAN_BUILDENV_REPOSITORY)"
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c  "cd /targets/mips-lenny && sb2 -eR ./debootstrap/debootstrap --second-stage"

debian/scratchbox-emulate:
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd /targets/mips-lenny && sb2 -e"

debian/scratchbox-emulate-fakeroot:
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd /targets/mips-lenny && sb2 -eR"

debian/clean:
	# sudo should not be needed if fakechroot would have worked
	sudo rm -rf $(DEBIAN_BUILD_DIR)
	rm -f debian/buildenv-setup
	rm -f debian/qemu-prepare 
	rm -f debian/qemu-build

.PHONY: debian/clean 

