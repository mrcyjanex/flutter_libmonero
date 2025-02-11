#!/bin/sh

. ./config.sh

WOWNERO_URL="https://git.wownero.com/wownero/wownero.git"
WOWNERO_VERSION=v0.11.0.1
WOWNERO_SHA_HEAD="a21819cc22587e16af00e2c3d8f70156c11310a0"
WOWNERO_SRC_DIR=${WORKDIR}/wownero

echo "Cloning wownero from - $WOWNERO_URL to - $WOWNERO_SRC_DIR"		
git clone ${WOWNERO_URL} ${WOWNERO_SRC_DIR} --branch ${WOWNERO_VERSION}
cd $WOWNERO_SRC_DIR
git reset --hard $WOWNERO_SHA_HEAD
git submodule init
git submodule update
git apply --stat --apply ${CW_ROOT}/patches/wownero/refresh_thread.patch

for arch in $TYPES_OF_BUILD
do
FLAGS=""
PREFIX=${WORKDIR}/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/wownero
DEST_INCLUDE_DIR=${PREFIX}/include/wownero
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR
LIBUNBOUND_PATH=${PREFIX}/lib/libunbound.a
if [ -f "$LIBUNBOUND_PATH" ]; then
  cp $LIBUNBOUND_PATH $DEST_LIB_DIR
fi

case $arch in
	"x86_64"	)
		BUILD_64=ON
		TAG="linux-x86_64"
		ARCH="x86-64"
		ARCH_ABI="x86_64";;
	"aarch64"	)
		BUILD_64=ON
		TAG="linux-aarch64"
		ARCH="aarch64"
		ARCH_ABI="aarch64";;
esac

cd $WOWNERO_SRC_DIR
rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release
cmake -DCMAKE_CXX_FLAGS="-fPIC" -D USE_DEVICE_TREZOR=OFF -D BUILD_GUI_DEPS=1 -D BUILD_TESTS=OFF -D ARCH=${ARCH} -D STATIC=ON -D BUILD_64=${BUILD_64} -D CMAKE_BUILD_TYPE=release -D INSTALL_VENDORED_LIBUNBOUND=ON -D BUILD_TAG=${TAG} $FLAGS ../..

make wallet_api -j$THREADS
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;

cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
cp -r $CMAKE_LIBRARY_PATH/*.a $DEST_LIB_DIR

CW_DIR="$(pwd)"/../../../../../../../flutter_libmonero
CW_WOWNERO_EXTERNAL_DIR=${CW_DIR}/cw_wownero/ios/External/android	
mkdir -p $CW_WOWNERO_EXTERNAL_DIR/include	
cp ../../src/wallet/api/wallet2_api.h ${CW_WOWNERO_EXTERNAL_DIR}/include
done
