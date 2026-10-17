SUMMARY = "Matching Algorithm with Recursively Implemented StorAge"
HOMEPAGE = "https://github.com/s-yata/marisa-trie"
LICENSE = "BSD-2-Clause | LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=8ae68bfcff9736d841121a37489b26be"

SRC_URI = "git://github.com/s-yata/marisa-trie.git;protocol=https;branch=master"
SRCREV = "6f13f31f798a93a6b08d3be0727120e9af35851f"
PV = "0.2.6"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE += "-DBUILD_SHARED_LIBS=ON"
