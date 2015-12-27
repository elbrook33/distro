#!/bin/sh

LC_ALL=POSIX
export LC_ALL

defaultCPPFLAGS=
defaultCFLAGS="-fPIC"
defaultCXXFLAGS="-fPIC"
defaultLDFLAGS="-static"
CPPFLAGS=$defaultCPPFLAGS
CFLAGS=$defaultCFLAGS
CXXFLAGS=$defaultCXXFLAGS
LDFLAGS=$defaultLDFLAGS
export CPPFLAGS CFLAGS CXXFLAGS LDFLAGS

setInstallPaths() {
	pathOptions="--prefix=/$softwareType/$1"
	installCategory=$softwareType/$1
}

buildBase() {
# Parameters:
# $1 - Package
# $2 - inTree/outOfTree
# $3 - Extra configure options
	packageDir=`tar -tf ../Packages/$1-* | head -n 1 | cut -d "/" -f 1`
	packageName=$1
	
	if [ `grep -c $packageDir Installed.list` -gt 0 ] ; then
		echo "Skipping $packageName"
		return
	else
		echo "Building $packageName"
	fi

	# Extract package
	if [ ! -d $packageDir ] ; then
		tar -xf ../Packages/$1-*
	fi
	if [ $2 = "outOfTree" ] && [ ! -d $packageName-build ] ; then
		mkdir $packageName-build
	fi
	
	# Patch
	cd $packageDir
		if [ -z $crossCompiling ] ; then
			sed -i "s|/usr/bin/file|file|g" `find . -name configure`
		fi
		if [ -f ../../Patches/$packageName.patch ] && [ ! -f .hasBeenPatched ] ; then
			patch -p1 < ../../Patches/$packageName.patch \
			&& touch .hasBeenPatched
		fi
	cd ..
	
	# Build
	[ $2 = "outOfTree" ] && cd $packageName-build || cd $packageDir
		../$packageDir/configure $pathOptions $3 >>config.log
		make -j3 CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" >>make.log
		if make install DESTDIR=$installPath >> install.log ; then
			cd ..
			rm -Rf $packageDir && rm -Rf $packageName-build
			echo $packageDir >>Installed.list
		else
			cd ..
	fi
}

buildPkg() {
	buildBase "$1" "outOfTree" "$2"
}
buildInTree() {
	buildBase "$1" "inTree" "$2"
}

findExecPaths() {
	PATH=/Software/Core/Command-line/bin
	NEWPATH=
	NEWPATH=$NEWPATH:`find /Apps/*/bin -maxdepth 0 -type d -printf "%p:"`
	NEWPATH=$NEWPATH:`find /Software/Core/*/bin -maxdepth 0 -type d -printf "%p:"`
	NEWPATH=$NEWPATH:`find /Software/Extras/*/bin -maxdepth 0 -type d -printf "%p:"`
	NEWPATH=$NEWPATH:`find /Apps/*/sbin -maxdepth 0 -type d -printf "%p:"`
	NEWPATH=$NEWPATH:`find /Software/Core/*/sbin -maxdepth 0 -type d -printf "%p:"`
	NEWPATH=$NEWPATH:`find /Software/Extras/*/sbin -maxdepth 0 -type d -printf "%p:"`
	export PATH=$NEWPATH
}

findBuildPaths() {
	CFLAGS=$defaultCFLAGS
	CXXFLAGS=$defaultCXXFLAGS
	CPATHS="-I/System/include"
	CPATHS="$CPATHS `find /Apps/*/include -maxdepth 0 -type d -printf " -I%p"`"
	CPATHS="$CPATHS `find /Software/Core/*/include -maxdepth 0 -type d -printf " -I%p"`"
	CPATHS="$CPATHS `find /Software/Extras/*/include -maxdepth 0 -type d -printf " -I%p"`"
	export CFLAGS="$CFLAGS $CPATHS"
	export CXXFLAGS="$CXXFLAGS $CPATHS"

	LDFLAGS=$defaultLDFLAGS
	LDPATHS=
	LDPATHS="$LDPATHS `find /Apps/*/lib -maxdepth 0 -type d -printf " -L%p"`"
	LDPATHS="$LDPATHS `find /Software/Core/*/lib -maxdepth 0 -type d -printf " -L%p"`"
	LDPATHS="$LDPATHS `find /Software/Extras/*/lib -maxdepth 0 -type d -printf " -L%p"`"
	export LDFLAGS="$LDFLAGS $LDPATHS"
}
