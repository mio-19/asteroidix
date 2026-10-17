SUMMARY = "A 2048 game clone for AsteroidOS"
HOMEPAGE = "https://github.com/MagneFire/asteroid-2048"
LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SRC_URI = " \
    file://CMakeLists.txt \
    file://LICENSE \
    file://runscript.in \
    file://2048.svg \
    file://asteroid-2048.desktop.template \
    file://i18n/asteroid-2048.desktop.h \
    file://i18n/asteroid-2048.en_GB.ts \
    file://src/CMakeLists.txt \
    file://src/main.cpp \
    file://src/main.qml \
    file://src/Game.qml \
"

S = "${UNPACKDIR}"

inherit qt6-cmake

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native qtbase"
RDEPENDS:${PN} += "qml-asteroid"

FILES:${PN} += "${libdir}/${PN}.so ${datadir}/applications/ ${datadir}/icons/ ${datadir}/translations/"
