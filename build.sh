#!/bin/bash

# http://www.nongnu.org/avr-libc/user-manual/install_tools.html

# For optimum compile time this should generally be set to the number of CPU cores your machine has
JOBCOUNT=1

# Build Linux toolchain
# A Linux AVR-GCC toolchain is required to build a Windows toolchain
# If the Linux toolchain has already been built then you can set this to 0
BUILD_LINUX=1

# Build 32 bit Windows toolchain
BUILD_WIN32=0

# Build 64 bit Windows toolchain
BUILD_WIN64=1

# Build AVR-LibC
BUILD_LIBC=1

# Output locations for built toolchains
PREFIX_LINUX=./build/linux
PREFIX_WIN32=./build/win32
PREFIX_WIN64=./build/win64
PREFIX_LIBC=./build/libc

# Install packages
apt-get install -y -qq wget make mingw-w64 gcc g++ bzip2

# Stop on errors
set -e

NAME_BINUTILS="binutils-2.26"
NAME_GCC="gcc-6.1.0"
NAME_LIBC="avr-libc-2.0.0"

HOST_WIN32="i686-w64-mingw32"
HOST_WIN64="x86_64-w64-mingw32"

OPTS_BINUTILS="
	--target=avr
	--disable-nls
"

OPTS_GCC="
	--target=avr
	--enable-languages=c,c++
	--disable-nls
	--disable-libssp
	--disable-libada
	--with-dwarf2
	--disable-shared
	--enable-static
"

OPTS_LIBC=""

TIME_START=$(date +%s)

makeDir()
{
	rm -rf "$1/"
	mkdir -p "$1"
}

echo "Clearing output directories..."
[ $BUILD_LINUX -eq 1 ] && makeDir "$PREFIX_LINUX"
[ $BUILD_WIN32 -eq 1 ] && makeDir "$PREFIX_WIN32"
[ $BUILD_WIN64 -eq 1 ] && makeDir "$PREFIX_WIN64"
[ $BUILD_LIBC -eq 1 ] && makeDir "$PREFIX_LIBC"

PATH="$PATH":"$PREFIX_LINUX"/bin
export PATH

CC=""
export CC

echo "Downloading sources..."
rm -f $NAME_BINUTILS.tar.bz2
rm -rf $NAME_BINUTILS/
wget ftp://ftp.mirrorservice.org/sites/ftp.gnu.org/gnu/binutils/$NAME_BINUTILS.tar.bz2
rm -f $NAME_GCC.tar.bz2
rm -rf $NAME_GCC/
wget ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/$NAME_GCC/$NAME_GCC.tar.bz2
if [ $BUILD_LIBC -eq 1 ]; then
	rm -f $NAME_LIBC.tar.bz2
	rm -rf $NAME_LIBC/
	wget ftp://ftp.mirrorservice.org/sites/download.savannah.gnu.org/releases/avr-libc/$NAME_LIBC.tar.bz2
fi

confMake()
{
	../configure --prefix=$1 $2 $3 $4
	make -j $JOBCOUNT
	make install-strip
	rm -rf *
}

# Make AVR-Binutils
echo "Making Binutils..."
echo "Extracting..."
bunzip2 -c $NAME_BINUTILS.tar.bz2 | tar xf -
mkdir -p $NAME_BINUTILS/obj-avr
cd $NAME_BINUTILS/obj-avr
[ $BUILD_LINUX -eq 1 ] && confMake "$PREFIX_LINUX" "$OPTS_BINUTILS"
[ $BUILD_WIN32 -eq 1 ] && confMake "$PREFIX_WIN32" "$OPTS_BINUTILS" --host=$HOST_WIN32 --build=`../config.guess`
[ $BUILD_WIN64 -eq 1 ] && confMake "$PREFIX_WIN64" "$OPTS_BINUTILS" --host=$HOST_WIN64 --build=`../config.guess`
cd ../../

# Make AVR-GCC
echo "Making GCC..."
echo "Extracting..."
bunzip2 -c $NAME_GCC.tar.bz2 | tar xf -
mkdir -p $NAME_GCC/obj-avr
cd $NAME_GCC
./contrib/download_prerequisites
cd obj-avr
[ $BUILD_LINUX -eq 1 ] && confMake "$PREFIX_LINUX" "$OPTS_GCC"
[ $BUILD_WIN32 -eq 1 ] && confMake "$PREFIX_WIN32" "$OPTS_GCC" --host=$HOST_WIN32 --build=`../config.guess`
[ $BUILD_WIN64 -eq 1 ] && confMake "$PREFIX_WIN64" "$OPTS_GCC" --host=$HOST_WIN64 --build=`../config.guess`
cd ../../

# Make AVR-LibC
if [ $BUILD_LIBC -eq 1 ]; then
	echo "Making AVR-LibC..."
	echo "Extracting..."
	bunzip2 -c $NAME_LIBC.tar.bz2 | tar xf -
	mkdir -p $NAME_LIBC/obj-avr
	cd $NAME_LIBC/obj-avr
	confMake "$PREFIX_LIBC" "$OPTS_LIBC" --host=avr --build=`../config.guess`
	cd ../../
fi

TIME_END=$(date +%s)
TIME_RUN=$(($TIME_END - $TIME_START))

echo ""
echo "Done in $TIME_RUN seconds"

exit 0
