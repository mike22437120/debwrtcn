# DebWrt - Debian on Embedded devices
#
# Copyright (C) 2010 Johan van Zoomeren
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

all: config/mconf/mconf

config/mconf/mconf:
	@$(MAKE) -s -C config/mconf all

config/mconf/conf:
	@$(MAKE) -s -C config/mconf conf

config-clean: FORCE
	$(MAKE) -C config/mconf clean

.config:
	@echo "Please run make menuconfig to create a configuration. Then run make again. Use make help so see all options."
	@exit 1

config: config/mconf/conf FORCE
	$< Config.in

defconfig: config/mconf/conf FORCE
	touch .config
	$< -D .config Config.in

oldconfig: config/mconf/conf FORCE
	$< -o Config.in

menuconfig: config/mconf/mconf FORCE
	$< Config.in

