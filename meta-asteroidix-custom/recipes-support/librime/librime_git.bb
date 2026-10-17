SUMMARY = "Rime Input Method Engine, the core library"
HOMEPAGE = "https://github.com/rime/librime"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e644d7ab18e9e31eb61c7574b714b7e5"

DEPENDS = "boost glog yaml-cpp marisa leveldb"

SRC_URI = " \
    git://github.com/rime/librime.git;protocol=https;branch=master;nobranch=1 \
    file://0001-CMakeLists-add-ENABLE_OPENCC-option.patch \
"
SRCREV = "c7ab6390c143a11d670f3add41218111edb883c9"
PV = "1.12.0"


inherit cmake pkgconfig

EXTRA_OECMAKE += " \
    -DBUILD_STATIC=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_LOGGING=ON \
    -DBUILD_TEST=OFF \
    -DENABLE_OPENCC=OFF \
"
