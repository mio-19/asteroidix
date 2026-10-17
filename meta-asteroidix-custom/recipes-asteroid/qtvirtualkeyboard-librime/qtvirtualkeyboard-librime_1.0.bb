SUMMARY = "Qt 6 Virtual Keyboard plugin for Rime CJK input method"
HOMEPAGE = "https://github.com/rime/librime"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

SRC_URI = " \
    file://src/CMakeLists.txt \
    file://src/plugin.json \
    file://src/qtvirtualkeyboard_librime_plugin.h \
    file://src/qtvirtualkeyboard_librime_plugin.cpp \
    file://src/rimeinputmethod.h \
    file://src/rimeinputmethod.cpp \
"

S = "${UNPACKDIR}/src"

inherit qt6-cmake pkgconfig

DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtvirtualkeyboard \
    librime \
"

RDEPENDS:${PN} += " \
    qtvirtualkeyboard \
    librime \
    rime-data \
"

FILES:${PN} += "${libdir}/qt6/plugins/virtualkeyboard/libqtvirtualkeyboard_librime.so"
