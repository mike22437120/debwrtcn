#!/bin/bash
#

if [ "$3" == "" ]; then
	echo "usage: `basename $0` source-kmod-package.ipk  extract-directory tmp-directory"
	echo
	exit 0
fi

kmodp=$1
droot=$2
tmpdir=$3

if [ ! -d "$droot" ]; then $droot is not a directory; exit 1; fi
if [ ! -d "$tmpdir" ]; then $tmpdir is not a directory; exit 1; fi

[ ! -e $kmodp ] && exit 1
[ ! -e $kmodp ] && echo "${kmodp} not found" && exit 1

tardir=$tmpdir/.extractkmodpkg.$$
mkdir -p $tardir

# Extra from data.tar.gz only /lib
n=`basename $kmodp`
nn=${n/.ipk/}
#echo -n "I: Extracting $nn..."
#( cat $kmodp\
#| gunzip \
#| tar -C . -x -f - -O ./data.tar.gz \
#| tar xzf - -C $tardir ./lib ) || true
tar xzf $kmodp -C $tardir ./data.tar.gz
tar xzf $tardir/data.tar.gz -C $tardir ./lib
echo -n "I: Copy kernel modules(s) from $nn..."
findc=0
first=1
for kmod in `find $tardir -type f -name "*.ko"`; do
   kmodf=`basename $kmod`
   findc=$(find $droot -type f -name $kmodf | wc -l)
   if [ "$findc" -eq 0 ]; then
	  tokmod=${kmod/$tardir/}
      todir=`dirname $droot/$tokmod`
	  mkdir -p $todir
      cp -a $kmod $droot/$tokmod
	  if [ "$first" = 1 ]; then echo; first=0; fi;
	  echo "I:    - $kmodf"
   fi
done

if [ "$findc" == 0 ]; then echo "I: done"; else echo "no"; fi

rm -rf $tardir

exit 0

