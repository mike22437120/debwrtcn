#!/bin/bash
#
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

CONFIG_FILE=$1
BOARD=$2

if [ -f $CONFIG_FILE ]; then
	cat $CONFIG_FILE \
	| grep CONFIG_TARGET_${BOARD}[^=] \
	| grep -v "#" \
	| awk '{print length($0)"\t"$0}' \
	| sort -n -r \
	| cut -f 2- \
	| head -1 \
	| sed -e "s/CONFIG_TARGET_${BOARD}_//" -e 's/=.*//'
fi
