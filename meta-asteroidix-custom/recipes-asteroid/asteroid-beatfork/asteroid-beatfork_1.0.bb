SUMMARY = "A metronome, tap BPM detector, and tuning fork app for AsteroidOS"
HOMEPAGE = "https://github.com/moWerk/asteroid-beatfork"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

SRC_URI = " \
    file://CMakeLists.txt \
    file://LICENSE \
    file://asteroid-beatfork.desktop.template \
    file://i18n/asteroid-beatfork.desktop.h \
    file://i18n/asteroid-beatfork.de.ts \
    file://i18n/asteroid-beatfork.en.ts \
    file://i18n/asteroid-beatfork.es.ts \
    file://i18n/asteroid-beatfork.fr.ts \
    file://i18n/asteroid-beatfork.it.ts \
    file://src/CMakeLists.txt \
    file://src/main.cpp \
    file://src/main.qml \
    file://src/BpmDetectPage.qml \
    file://src/MetronomePage.qml \
    file://src/TuningForkPage.qml \
    file://src/ToneGenerator.h \
    file://src/ToneGenerator.cpp \
    file://src/resources.qrc \
    file://src/tick.wav \
    file://src/events.d/beatfork-tick.ini \
"

S = "${UNPACKDIR}"

inherit qt6-cmake pkgconfig

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native qtbase qtmultimedia"
RDEPENDS:${PN} += "qml-asteroid qtmultimedia"

FILES:${PN} += "${bindir}/${PN} ${datadir}/applications/ ${datadir}/sounds/ ${datadir}/ngfd/events.d/ ${datadir}/translations/"
