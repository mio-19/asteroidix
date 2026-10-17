SUMMARY = "Matching Algorithm with Recursively Implemented StorAge"
HOMEPAGE = "https://github.com/s-yata/marisa-trie"
LICENSE = "BSD-2-Clause | LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=e759fcb612bd54a9ec6984d95014742b"

SRC_URI = "git://github.com/s-yata/marisa-trie.git;protocol=https;branch=master"
SRCREV = "38180f6d3653cd2c88dd7047711e75f48f84527c"
PV = "0.2.6+git"


inherit cmake pkgconfig

EXTRA_OECMAKE += "-DBUILD_SHARED_LIBS=ON"
