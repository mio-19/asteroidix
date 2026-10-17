SUMMARY = "Rime Input Method Engine, the core library"
HOMEPAGE = "https://github.com/rime/librime"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=2da482c005228eb21484a2d3c0ed9508"

DEPENDS = "boost glog yaml-cpp marisa leveldb"

SRC_URI = "git://github.com/rime/librime.git;protocol=https;branch=master"
SRCREV = "c0f258ce9e5c587ff87ae01e47a0a34dd950bc7c"
PV = "1.12.0"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE += " \
    -DBUILD_STATIC=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_LOGGING=ON \
    -DBUILD_TEST=OFF \
"
