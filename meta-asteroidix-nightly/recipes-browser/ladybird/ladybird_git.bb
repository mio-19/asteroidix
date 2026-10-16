SUMMARY = "Ladybird Web Browser"
DESCRIPTION = "Independent, modern, standards-compliant web browser and engine"
HOMEPAGE = "https://ladybird.org"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=82c52a5ecbde10e85c9cdb89a6a07b16"

# Ladybird's LibGC and LibJS fundamentally require a 64-bit architecture.
# On AsteroidOS, this restricts compatibility to the Qualcomm SW5100 targets (aarch64).
COMPATIBLE_HOST = "aarch64.*-linux"
COMPATIBLE_MACHINE = "aurora|eos|solios|seluna"

SRC_URI = "git://github.com/LadybirdBrowser/ladybird.git;protocol=https;branch=master"
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
    -DCMAKE_BUILD_TYPE=Release \
"

FILES:${PN} += "${bindir}/Ladybird ${libexecdir}/ ${datadir}/ladybird/"
