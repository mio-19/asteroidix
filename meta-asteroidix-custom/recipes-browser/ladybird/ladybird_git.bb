SUMMARY = "Ladybird Web Browser"
DESCRIPTION = "Independent, modern, standards-compliant web browser and engine"
HOMEPAGE = "https://ladybird.org"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=82c52a5ecbde10e85c9cdb89a6a07b16"

# Ladybird natively targets 64-bit systems, with experimental 32-bit support via LibGC cage scaling.
COMPATIBLE_HOST = "aarch64.*-linux|arm.*-linux"
COMPATIBLE_MACHINE = "aurora|eos|solios|seluna|hoki"

SRC_URI = " \
    git://github.com/LadybirdBrowser/ladybird.git;protocol=https;branch=master \
    file://0001-Support-32-bit-ARM-in-AK-and-LibGC.patch \
    file://ladybird.desktop \
    file://ladybird-wrapper \
"
SRCREV = "b90af890b56cbd51c452d929fe71abcb8adaa36f"

inherit cmake qt6-cmake pkgconfig

DEPENDS = " \
    qtbase \
    qtwayland \
    qtmultimedia \
    openssl \
    curl \
    zlib \
    libpng \
    jpeg \
    libxml2 \
    ffmpeg \
    fontconfig \
    harfbuzz \
    rust-native \
    cargo-native \
"

EXTRA_OECMAKE += " \
    -DENABLE_QT=ON \
    -DENABLE_JS_JIT=OFF \
    -DENABLE_CRANELIFT_JIT=OFF \
    -DCMAKE_BUILD_TYPE=Release \
"

do_install:append() {
    install -d ${D}${bindir} ${D}${datadir}/applications
    WRAPPER_SRC="${UNPACKDIR}/ladybird-wrapper"
    [ -f "$WRAPPER_SRC" ] || WRAPPER_SRC="${WORKDIR}/ladybird-wrapper"
    DESKTOP_SRC="${UNPACKDIR}/ladybird.desktop"
    [ -f "$DESKTOP_SRC" ] || DESKTOP_SRC="${WORKDIR}/ladybird.desktop"
    install -m 0755 "$WRAPPER_SRC" ${D}${bindir}/ladybird-wrapper
    install -m 0644 "$DESKTOP_SRC" ${D}${datadir}/applications/ladybird.desktop
    ln -sf ladybird-wrapper ${D}${bindir}/ladybird
}

FILES:${PN} += "${bindir}/Ladybird ${bindir}/ladybird ${bindir}/ladybird-wrapper ${libexecdir}/ ${datadir}/ladybird/ ${datadir}/applications/"

