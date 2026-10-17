SUMMARY = "AsteroidOS OTA System Update Application and Daemon"
HOMEPAGE = "https://github.com/mio-19/asteroidix"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1e1693ccfb0a99e67719cfc99121ddb3"

SRC_URI = " \
    file://CMakeLists.txt \
    file://LICENSE \
    file://runscript.in \
    file://asteroid-ota.desktop.template \
    file://asteroid-otad.service \
    file://org.asteroidos.OTA1.conf \
    file://i18n/asteroid-ota.desktop.h \
    file://src/CMakeLists.txt \
    file://src/main.cpp \
    file://src/main.qml \
    file://src/otaclient.h \
    file://src/otaclient.cpp \
    file://src/otadaemon.h \
    file://src/otadaemon.cpp \
    file://src/otadaemon_main.cpp \
"

S = "${UNPACKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "asteroid-otad.service"
SYSTEMD_AUTO_ENABLE = "enable"

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native qtbase"
RDEPENDS:${PN} += "qml-asteroid opkg systemd"

FILES:${PN} += " \
    ${bindir}/${PN} \
    ${libdir}/${PN}.so \
    ${datadir}/applications/ \
    ${datadir}/dbus-1/system.d/ \
    ${systemd_system_unitdir}/ \
    ${libexecdir}/asteroid-otad \
"
