# Host build fails on kernels/glibc exposing EFSBADCRC/EFSCORRUPTED errno aliases (linux 7.0+).
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://0001-errno-list-filter-out-EFSBADCRC-and-EFSCORRUPTED.patch"
