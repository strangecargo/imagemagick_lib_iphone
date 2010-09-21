#!/bin/bash

# Author: Claudio Marforio
# e-mail: marforio@gmail.com
# date: 21.06.2010

# Script to make static libraries (jpeg + png + tiff) and ImageMagick
# the libraries will be conbined into i386+arm.a static libraries
#	to be used inside an XCODE project for iPhone development

# The directory structure has to be:
# ~/Desktop/cross_compile/ImageMagick-VERSION/	 <- ImageMagick top directory
#	            |        /IMDelegataes/	 <- Some delegates, in particular jpeg + png + tiff
#	            |           |-jpeg-6b/          <- Patched jpeg6b
#	            |           |-libpng-1.4.2     <- png lib -- no need to patch it
#	            |           |-tiff-3.9.2        <- tiff lib -- no need to patch it
#	            |- ...	 <- we don't care what's here! :)

# If you don't have this directory structure you can either create it or try change around the script

# If everything works correctly you will end up with a folder
# on your ~/Desktop ready to be imported into XCode
# change this line if you want for everything to be
# exported somewhere else

FINAL_DIR=~/Desktop/IMPORT_ME/

if [[ $# != 1 ]]; then
	echo "imagemagick_compile.sh takes 1 argument: the version of ImageMagick that you want to compile!"
	echo "USAGE: imagemagick_compile.sh 6.6.1-7"
	exit
fi

IM_VERSION="$1"
IM_DIR="/Users/$USER/Desktop/cross_compile/ImageMagick-$IM_VERSION"
IM_DELEGATES_DIR="$IM_DIR/IMDelegates/"

if [ -d $IM_DELEGATES_DIR ]; then
	echo "IMDelegates folder present in: $IM_DELEGATES_DIR"
else
	echo "IMDelegates folder not found, copying over"
	cp -r "/Users/$USER/Desktop/cross_compile/IMDelegates" "$IM_DIR/IMDelegates"
fi

# Architectures and versions
ARCH_x86="i386"
ARCH_ARMV6="armv6"
ARCH_ARMV7="armv7"
CLANG_VERSION="1.5"
MIN_IPHONE_VERSION="4.1"
IPHONE_SDK_VERSION="4.1"

# Set this to where you want the libraries to be placed (if dir is not present it will be created):
TARGET_LIB_DIR=$(pwd)/tmp_target
LIB_DIR=$TARGET_LIB_DIR/im_libs
IM_LIB_DIR=$TARGET_LIB_DIR/imagemagick

# Set the build directories
mkdir -p $TARGET_LIB_DIR
mkdir -p $LIB_DIR/include/im_config
mkdir -p $LIB_DIR/include/magick
mkdir -p $LIB_DIR/include/wand

# General folders where you have the iPhone compiler + tools
export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
# Change this to match for which version of the SDK you want to compile -- you can change the number for the version
export SDKROOT=$DEVROOT/SDKs/iPhoneOS4.1.sdk
export MACOSXROOT=/Developer/SDKs/MacOSX10.6.sdk

# Compiler flags and config arguments - IPHONE
COMMON_IPHONE_LDFLAGS="-L$SDKROOT/usr/lib/"
COMMON_IPHONE_CFLAGS="-miphoneos-version-min=$MIN_IPHONE_VERSION -pipe -Os -isysroot $SDKROOT \
-I$SDKROOT/usr/include -I$SDKROOT/usr/lib/clang/$CLANG_VERSION/include/"

IM_LDFLAGS="-L$LIB_DIR"
IM_IFLAGS=""

###########################################
############    IMAGEMAGICK    ############
###########################################

function im() {

cd $IM_DIR

# static library that will be generated
LIBPATH_static=$IM_LIB_DIR/lib/libMagickCore.a
LIBNAME_static=`basename $LIBPATH_static`
LIBPATH_static2=$IM_LIB_DIR/lib/libMagickWand.a
LIBNAME_static2=`basename $LIBPATH_static2`

if [ "$1" == "$ARCH_ARMV6" ]; then ##  ARMV6	 ##

# Save relevant environment
U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$IM_LDFLAGS $COMMON_IPHONE_LDFLAGS"
export CFLAGS="-arch armv6 $COMMON_IPHONE_CFLAGS $IM_IFLAGS -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export CXXFLAGS="-Wall -W -D_THREAD_SAFE -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"

# configure to have the static libraries and make
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin \
--disable-largefile --without-magick-plus-plus --without-perl --without-x \
--disable-shared --without-bzlib --without-zlib --without-png --without-freetype

# compile ImageMagick
make -j2
make install

# copy the CORE + WAND libraries -- ARM version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.armv6
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.armv6

# clean the ImageMagick build
make distclean

elif [ "$1" == "$ARCH_ARMV7" ]; then ##  ARMV7	 ##

export LDFLAGS="$IM_LDFLAGS $COMMON_IPHONE_LDFLAGS"
export CFLAGS="-arch armv7 $COMMON_IPHONE_CFLAGS $IM_IFLAGS -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export CXXFLAGS="-Wall -W -D_THREAD_SAFE -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"

# configure to have the static libraries and make
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin \
--disable-largefile --without-magick-plus-plus --without-perl --without-x \
--disable-shared --without-bzlib --without-zlib --without-png --without-freetype

# compile ImageMagick
make -j2
make install

# copy the CORE + WAND libraries -- ARM version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.armv7
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.armv7

# clean the ImageMagick build
make distclean

elif [ "$1" == "$ARCH_x86" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export LDFLAGS="-isysroot $MACOSXROOT -mmacosx-version-min=10.6"
export CFLAGS="-arch $ARCH_x86 -isysroot $MACOSXROOT -mmacosx-version-min=10.6 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export LD=$U_LD
export CPP=$U_CPP
export CPPFLAGS="$U_CPPFLAGS $U_LDFLAGS $IM_IFLAGS -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"

# configure with standard parameters
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang --host=i686-apple-darwin10 \
--disable-largefile --without-magick-plus-plus --without-perl --without-x \
--disable-shared --without-bzlib --without-zlib --without-png --without-freetype

# compile ImageMagick
make -j2
make install

# copy the CORE + WAND libraries -- INTEL version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.i386
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.i386

# copy the wand/ + core/ headers
cp $IM_LIB_DIR/include/ImageMagick/magick/* $LIB_DIR/include/magick/
cp $IM_LIB_DIR/include/ImageMagick/wand/* $LIB_DIR/include/wand/

# copy configuration files needed for certain functions
cp $IM_LIB_DIR/lib/ImageMagick-*/config/*.xml $LIB_DIR/include/im_config/
cp $IM_LIB_DIR/share/ImageMagick-*/config/*.xml $LIB_DIR/include/im_config/
cp $IM_LIB_DIR/share/ImageMagick-*/config/*.icm $LIB_DIR/include/im_config/

# clean the ImageMagick build
make distclean

# combine the two generated libraries to be used both in the simulator and in the device
$DEVROOT/usr/bin/lipo $LIB_DIR/$LIBNAME_static.armv6 $LIB_DIR/$LIBNAME_static.armv7 $LIB_DIR/$LIBNAME_static.i386 -create -output $LIB_DIR/$LIBNAME_static
$DEVROOT/usr/bin/lipo $LIB_DIR/$LIBNAME_static2.armv6 $LIB_DIR/$LIBNAME_static2.armv7 $LIB_DIR/$LIBNAME_static2.i386 -create -output $LIB_DIR/$LIBNAME_static2

fi

} ## END IMAGEMAGICK LIBRARY ##

function structure_for_xcode() {
	echo "-------------- Making everything ready to import! --------------"
	if [ -e $FINAL_DIR ]; then
		echo "Directory $FINAL_DIR is already present"
		rm -rf "$FINAL_DIR"*
	else
		echo "Creating directory for importing into XCode: $FINAL_DIR"
		mkdir -p "$FINAL_DIR"
	fi
	cp -r $LIB_DIR/include/ "$FINAL_DIR"include/
	cp $LIB_DIR/*.a "$FINAL_DIR"
	# echo "-------------- Removing tmp_target dir --------------"
	# 	rm -rf $TARGET_LIB_DIR
	echo "-------------- All Done! --------------"
}

# function used to produce .zips for the ImageMagick ftp site maintained by me (Claudio Marforio)
function zip_for_ftp() {
	echo "-------------- Preparing .zips for ftp.imagemagick.org! --------------"
	if [ -e $FINAL_DIR ]; then
		tmp_dir="/Users/$USER/Desktop/TMP_IM"
		cp -R $FINAL_DIR $tmp_dir
		ditto -c -k -rsrc "$tmp_dir" "iPhoneMagick-$IM_VERSION-libs.zip" && echo "-libs zip created" # creates -libs zip
		rm $tmp_dir/libjpeg.a $tmp_dir/libpng.a $tmp_dir/libtiff.a
		rm -rf $tmp_dir/include/jpeg/ $tmp_dir/include/png/ $tmp_dir/include/tiff/
		ditto -c -k -rsrc "$tmp_dir" "iPhoneMagick-$IM_VERSION.zip" && echo "im_only zip created" # creates im_only zip
		rm -rf $tmp_dir
	else
		echo "ERROR, $FINAL_DIR not present..."
	fi
	echo "-------------- All Done! --------------"
}

im "$ARCH_ARMV6"
im "$ARCH_ARMV7"
im "$ARCH_x86"
structure_for_xcode
# zip_for_ftp