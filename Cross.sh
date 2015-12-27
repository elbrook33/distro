#!/bin/sh
. ../Env.sh

crossCompiling=1
crossTarget=$(uname -m)-linux-musl
installPath=$1

sudo ln -s $installPath/Software /

# Build cross-compiler
if [ `grep -c gcc-$crossTarget Installed.list` -gt 0 ] ; then
	echo "Skipping cross-compiler"
else
	echo "Building cross-compiler"
	tar -xf ../Packages/crossx86-$crossTarget-*
	mkdir --parents $installPath/Software/Core/C-compiler	2>>Log
	mv $crossTarget/* $installPath/Software/Core/C-compiler
	rmdir $crossTarget
	for program in `ls $installPath/Software/Core/C-compiler/bin/$crossTarget-* | xargs -L 1 basename` ; do
		ln -s $program $installPath/Software/Core/C-compiler/bin/`echo $program | cut -d "-" -f 4-`
	done
	echo gcc-$crossTarget >> Installed.list
fi

# Build musl (again), for specs file
softwareType=Software/Core
CC=/Software/Core/C-compiler/bin/gcc
AR=/Software/Core/C-compiler/bin/ar
RANLIB=/Software/Core/C-compiler/bin/ranlib
export CC AR RANLIB

# Build basic (static) shell, enough to chroot and build
setInstallPaths "Archivers"
buildInTree bzip2
	# Fix absolute-path symlinks
	ln -sf bzdiff $installPath/Software/Core/Archivers/bin/bzcmp
	ln -sf bzgrep $installPath/Software/Core/Archivers/bin/bzegrep
	ln -sf bzgrep $installPath/Software/Core/Archivers/bin/bzfgrep
	ln -sf bzmore $installPath/Software/Core/Archivers/bin/bzless
	# Fix man folder location
	mkdir $installPath/Software/Core/Archivers/share	2>>Log
	mv $installPath/Software/Core/Archivers/man $installPath/Software/Core/Archivers/share/	2>>Log
buildPkg gzip
buildPkg tar
buildPkg xz	# Isn't building statically

setInstallPaths "Build-tools"
buildPkg bison
buildPkg diffutils
buildPkg make
buildPkg m4
buildPkg patch

setInstallPaths "Command-line"
buildPkg bash "--without-bash-malloc --enable-static-link"
	# Alias to sh
	ln -sf bash $installPath/Software/Core/Command-line/bin/sh
	# Copy default profile
	mkdir $installPath/Software/Core/Command-line/etc	2>>Log
	cp ../Patches/bash-profile $installPath/Software/Core/Command-line/etc/profile
buildPkg findutils
buildPkg gawk
buildPkg grep
buildPkg sed

# Special builds for coreutils and file
export CC=
softwareType=Software/Temporary
setInstallPaths "C-library"
buildInTree musl "--syslibdir=/Software/Temporary/C-library/lib"
export REALGCC=/Software/Core/C-compiler/bin/gcc
export CC=/Software/Temporary/C-library/bin/musl-gcc
softwareType=Software/Core
setInstallPaths "Command-line"
buildPkg coreutils
buildPkg file

# Clean up
sudo rm /Software
