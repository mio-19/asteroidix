SUMMARY = "AsteroidOS Metronome ported from Tack Android"
HOMEPAGE = "https://github.com/patzly/tack-android"
LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fd575b5a138d5971c4c45da379a1c510"

SRC_URI = " \
    file://CMakeLists.txt \
    file://LICENSE \
    file://runscript.in \
    file://asteroid-tack.desktop.template \
    file://i18n/asteroid-tack.desktop.h \
    file://events.d/asteroid-tack.ini \
    file://sounds/sine.wav \
    file://sounds/wood.wav \
    file://sounds/mechanical_ding.wav \
    file://sounds/mechanical_tick.wav \
    file://sounds/mechanical_knock.wav \
    file://sounds/hands_clap.wav \
    file://sounds/hands_snap.wav \
    file://src/CMakeLists.txt \
    file://src/main.cpp \
    file://src/tackengine.h \
    file://src/tackengine.cpp \
    file://src/tempotap.h \
    file://src/tempotap.cpp \
    file://src/main.qml \
    file://src/MainScreen.qml \
    file://src/BeatsScreen.qml \
    file://src/TempoScreen.qml \
    file://src/SettingsScreen.qml \
    file://src/BookmarksScreen.qml \
"

S = "${UNPACKDIR}"

inherit qt6-cmake

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native qtbase"
RDEPENDS:${PN} += "qml-asteroid"

FILES:${PN} += "${libdir}/${PN}.so ${datadir}/applications/ ${datadir}/sounds/tack/ ${datadir}/ngfd/events.d/"
