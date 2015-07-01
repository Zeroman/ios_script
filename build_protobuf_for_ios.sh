#!/bin/bash - 

CP='cp -fv'
MAKE='make -j5'
MIN_SDK=5.0

prepare_env()
{
    brew install autoconf automake
}

build_mac()
{
    test -e ./configure || ./autogen.sh
    ./configure
    $MAKE clean
    $MAKE
    sudo $MAKE install
}

build_arm()
{
    ARCHS_IPHONE_OS="-arch armv7 -arch armv7s -arch arm64"
    SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
    CC="$(xcrun --sdk iphoneos -f clang)"
    CXX=$(xcrun --sdk iphoneos -f clang++)
    CFLAGS="-isysroot $SDKROOT $ARCHS_IPHONE_OS -miphoneos-version-min=$MIN_SDK"
    CXXFLAGS=$CFLAGS
    export CC CXX CFLAGS CXXFLAGS

    BUILD_DIR=$PWD/build_arm
    ./configure --host=arm-apple-darwin --prefix=$BUILD_DIR --with-protoc=protoc --enable-static --disable-shared 
    $MAKE clean
    $MAKE
    $MAKE install
}

build_simulator()
{
    ARCHS_IPHONE_SIMULATOR="-arch i386 -arch x86_64"
    SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
    CC="$(xcrun --sdk iphonesimulator -f clang)"
    CXX="$(xcrun --sdk iphonesimulator -f clang++)"
    CFLAGS=" -isysroot $SDKROOT $ARCHS_IPHONE_SIMULATOR -mios-simulator-version-min=$MIN_SDK"
    CXXFLAGS=$CFLAGS
    export CC CXX CFLAGS CXXFLAGS

    BUILD_DIR=$PWD/build_x86
    ./configure --host=arm-apple-darwin --prefix=$BUILD_DIR --with-protoc=protoc --enable-static --disable-shared 
    $MAKE clean
    $MAKE
    $MAKE install
}


prepare_env

git clone https://github.com/google/protobuf.git

cd protobuf;

git checkout v2.6.1 -b v2.6.1

if ! which protoc > /dev/null;then
    build_mac
fi

if [ ! -e build_arm/lib/libprotobuf.a ];then
    build_arm
fi

if [ ! -e build_x86/lib/libprotobuf.a ];then
    build_simulator
fi

# create universal static library
lipo -create build_x86/lib/libprotobuf.a build_arm/lib/libprotobuf.a -output ../libprotobuf.a 
lipo -create build_x86/lib/libprotobuf-lite.a build_arm/lib/libprotobuf-lite.a -output ../libprotobuf-lite.a 
 
echo "************** Done **************"
lipo -info build_x86/lib/libprotobuf.a build_arm/lib/libprotobuf.a
lipo -info build_x86/lib/libprotobuf-lite.a build_arm/lib/libprotobuf-lite.a
lipo -info ../libprotobuf.a ../libprotobuf-lite.a 


