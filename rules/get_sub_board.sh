#!/bin/bash
#

CONFIG_FILE=$1
BOARD=$2

cat $CONFIG_FILE | grep CONFIG_TARGET_${BOARD}[^=] | grep -v "#" | awk '{print length($0)"\t"$0}' | sort -n -r | cut -f 2- | head -1 | sed -e "s/CONFIG_TARGET_${BOARD}_//" -e 's/=.*//'
