#!/bin/sh

if [ -z $1 ] ; then
	installPath=~/Desmond
else
	installPath=$1
fi
echo "Building to $installPath"

cd Build
	echo > Log
	touch Installed.list

	# Set up partition
	mkdir $installPath						2>>Log
	mkdir $installPath/Apps					2>>Log
	mkdir $installPath/Documents				2>>Log
	mkdir $installPath/Documents/Temporary	2>>Log
	mkdir $installPath/Documents/Trash		2>>Log
	mkdir $installPath/Shell					2>>Log
	mkdir $installPath/Shell/Apps				2>>Log
	mkdir $installPath/Shell/Documents		2>>Log
	mkdir $installPath/Shell/Software			2>>Log
	mkdir $installPath/Shell/System			2>>Log
	mkdir $installPath/Shell/bin				2>>Log
	mkdir $installPath/Shell/dev				2>>Log
	mkdir $installPath/Shell/lib				2>>Log
	mkdir $installPath/Shell/proc				2>>Log
	mkdir $installPath/Shell/sys				2>>Log
	mkdir $installPath/Software				2>>Log
	mkdir $installPath/System				2>>Log
	mkdir $installPath/System/etc				2>>Log
	
	ln -s /Software/Core/C-compiler/x86_64-linux-musl/lib/libc.so	$installPath/Shell/lib/ld-musl-x86_64.so.1	2>>Log
	
	ln -s /Software/Core/Command-line/bin/bash	$installPath/Shell/bin/bash	2>>Log
	ln -s /Software/Core/Command-line/bin/chroot	$installPath/Shell/bin/chroot	2>>Log
	ln -s /Software/Core/Command-line/bin/env	$installPath/Shell/bin/env		2>>Log
	ln -s bash									$installPath/Shell/bin/sh		2>>Log

	ln -s Documents/Temporary	$installPath/Shell/tmp	2>>Log
	ln -s System/etc				$installPath/Shell/etc		2>>Log
	ln -s .						$installPath/Shell/Shell	2>>Log
	
	cp ../Patches/etc-group	$installPath/System/etc/group	2>>Log

	# Install kernel
	if [ `grep -c linux-kernel Installed.list` -gt 0 ] ; then
		echo "Skipping kernel"
	else
		echo "Installing kernel"
		if [ ! -d linux-* ] ; then
			tar -xf ../Packages/linux-*
		fi
		cd linux-*
			make INSTALL_HDR_PATH=$installPath/System headers_install >> Log
		cd ..
		echo "linux-kernel" >> Installed.list
	fi

	# Cross-compile the base system, enough to run bash and make
	../Cross.sh $installPath

	# Chroot into partition and build some extras
	sudo mount --bind /dev		$installPath/Shell/dev
	sudo mount --bind /dev/pts	$installPath/Shell/dev/pts
	sudo mount --bind /proc		$installPath/Shell/proc
	sudo mount --bind /sys		$installPath/Shell/sys
	sudo mount --bind $installPath/Apps		$installPath/Shell/Apps
	sudo mount --bind $installPath/Documents	$installPath/Shell/Documents
	sudo mount --bind $installPath/Software	$installPath/Shell/Software
	sudo mount --bind $installPath/System		$installPath/Shell/System
		sudo chroot $installPath /Shell/bin/env -i /Shell/bin/chroot /Shell /bin/sh -l
	sudo umount $installPath/Shell/System
	sudo umount $installPath/Shell/Software
	sudo umount $installPath/Shell/Documents
	sudo umount $installPath/Shell/Apps
	sudo umount $installPath/Shell/sys
	sudo umount $installPath/Shell/proc
	sudo umount $installPath/Shell/dev/pts
	sudo umount $installPath/Shell/dev

	# Boot
	../Boot.sh
cd ..