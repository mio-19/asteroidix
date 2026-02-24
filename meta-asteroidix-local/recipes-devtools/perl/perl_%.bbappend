FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:class-native = " file://0001-errno-fallback-to-dM-when-header-scan-finds-nothing.patch"
