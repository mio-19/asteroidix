SUMMARY = "Ask the paired phone to ring"
HOMEPAGE = "https://github.com/mio-19/asteroidix"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1e1693ccfb0a99e67719cfc99121ddb3"

SRC_URI = " \
    file://CMakeLists.txt \
    file://LICENSE \
    file://runscript.in \
    file://asteroid-findphone.desktop.template \
    file://i18n/asteroid-findphone.desktop.h \
    file://src/CMakeLists.txt \
    file://src/main.cpp \
    file://src/main.qml \
    file://src/findphoneclient.h \
    file://src/findphoneclient.cpp \
"

S = "${UNPACKDIR}"

inherit qt6-cmake

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native qtbase"
RDEPENDS:${PN} += "asteroid-btsyncd qml-asteroid"

FILES:${PN} += "${libdir}/${PN}.so ${datadir}/applications/"
