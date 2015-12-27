#!/bin/sh
. ../Env.sh

export FORCE_UNSAFE_CONFIGURE=1

findExecPaths	2>>Log
findBuildPaths	2>>Log

softwareType=Software/Core
setInstallPaths "Device-tools"
buildPkg e2fsprogs
buildPkg kmod
	ln -s kmod /Software/Core/Device-tools/bin/depmod
	ln -s kmod /Software/Core/Device-tools/bin/insmod
	ln -s kmod /Software/Core/Device-tools/bin/lsmod
	ln -s kmod /Software/Core/Device-tools/bin/modinfo
	ln -s kmod /Software/Core/Device-tools/bin/modprobe
	ln -s kmod /Software/Core/Device-tools/bin/rmmod
buildPkg util-linux

setInstallPaths "Build-tools"
buildPkg pkg-config "--with-internal-glib"
