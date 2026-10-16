SUMMARY = "AsteroidOS Blood Oxygen (SpO2) Pulse Oximeter"
HOMEPAGE = "https://github.com/mio-19/asteroidix"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1052d93c655b7dd7d82c7a63cb5bc288"

SRC_URI = " \
    file://CMakeLists.txt \
    file://LICENSE \
    file://runscript.in \
    file://asteroid-spo2.desktop.template \
    file://i18n/asteroid-spo2.desktop.h \
    file://src/CMakeLists.txt \
    file://src/main.cpp \
    file://src/spo2controller.h \
    file://src/spo2controller.cpp \
    file://src/main.qml \
    file://src/OxygenMeter.qml \
"

S = "${UNPACKDIR}"

inherit qt6-cmake

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native qtbase qtsensors"
RDEPENDS:${PN} += "qml-asteroid qtsensors-qmlplugins"

FILES:${PN} += "${libdir}/${PN}.so ${datadir}/applications/"
