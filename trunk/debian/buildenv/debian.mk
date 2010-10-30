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

SB2_ARCH:=$(call qstrip,$(CONFIG_ARCH))
CHROOT:=sudo chroot $(DEBIAN_BUILD_DIR)
CHROOT_USER:=$(CHROOT) su - $(USER) -c bash
SB2:=sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd $(SB2_ARCH)-lenny && sb2"
SB2E:=sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd $(SB2_ARCH)-lenny && sb2 -e"
SB2EF:=sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd $(SB2_ARCH)-lenny && sb2 -eR"

sb2:
	$(SB2)
sb2e:
	$(SB2E)
sbef:
	$(SB2EF)
ch: chroot
chu: chroot-user
chroot:
	$(CHROOT)
chroot-user:
	$(CHROOT_USER)

debian/buildenv/create: debian/buildenv/prepare debian/buildenv/qemu-build debian/buildenv/scratchbox-prepare

debian/buildenv/prepare:
	mkdir -p $(DEBIAN_BUILD_DIR)
	# Due to various bugs in debootstrap in combination with fakechroot it is not 
	# possible to create a fakechroot here - and therefore we need to use chroot
	# with sudo
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
	#sudo chroot $(DEBIAN_BUILD_DIR) bash -c "export LC_ALL=C; apt-get -y --force-yes install g++-4.3-$(SB2_ARCH)-linux-gnu libc6-dev-$(SB2_ARCH)-cross build-essential debootstrap fakeroot zlib1g-dev qemu-user scratchbox2 dh-make"
	sudo chroot $(DEBIAN_BUILD_DIR) bash -c "export LC_ALL=C; apt-get -y --force-yes install g++-4.3-$(SB2_ARCH)-linux-gnu libc6-dev-$(SB2_ARCH)-cross build-essential debootstrap fakeroot zlib1g-dev scratchbox2 dh-make sudo openssh-client"
	sudo chroot $(DEBIAN_BUILD_DIR) groupadd -g $(shell id -g) debwrt
	sudo chroot $(DEBIAN_BUILD_DIR) useradd -g debwrt -s /bin/bash -m -u $(shell id -u) $$USER
	touch $@

debian/buildenv/qemu-prepare:
	sudo chroot $(DEBIAN_BUILD_DIR) bash -c "cd /usr/src && wget http://download.savannah.gnu.org/releases/qemu/qemu-$(call qstrip,$(CONFIG_DEBIAN_BUILDENV_QEMU_VERSION)).tar.gz && tar xzf qemu-$(call qstrip,$(CONFIG_DEBIAN_BUILDENV_QEMU_VERSION)).tar.gz"
	touch $@

debian/buildenv/qemu-build: debian/buildenv/qemu-prepare
	sudo chroot $(DEBIAN_BUILD_DIR) bash -c "cd /usr/src/qemu-$(call qstrip,$(CONFIG_DEBIAN_BUILDENV_QEMU_VERSION)) && ./configure --target-list=$(SB2_ARCH)-linux-user && make && make install"
	touch $@

debian/buildenv/scratchbox-prepare:
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "mkdir -p $(SB2_ARCH)-lenny"
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "cd $(SB2_ARCH)-lenny && sb2-init -c /usr/local/bin/qemu-$(SB2_ARCH) MIPS \"$(SB2_ARCH)-linux-gnu-gcc\""
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c "fakeroot /usr/sbin/debootstrap --include=file,iputils-ping,netbase,strace,vim,wget,tcpdump --variant=scratchbox --foreign --arch $(SB2_ARCH) lenny $(SB2_ARCH)-lenny/ $(CONFIG_DEBIAN_BUILDENV_REPOSITORY)"
	sudo chroot $(DEBIAN_BUILD_DIR) su - $(USER) -c bash -c  "cd $(SB2_ARCH)-lenny && sb2 -eR ./debootstrap/debootstrap --second-stage"

debian/buildenv/clean:
	# sudo should not be needed if fakechroot would have worked
	sudo rm -rf $(DEBIAN_BUILD_DIR)
	rm -f debian/buildenv/-prepare
	rm -f debian/buildenv/qemu-prepare 
	rm -f debian/buildenv/qemu-build

.PHONY: debian/clean 

