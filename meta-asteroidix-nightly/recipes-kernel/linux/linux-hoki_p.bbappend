FILESEXTRAPATHS:prepend := "${THISDIR}/linux-hoki:${THISDIR}/files:"

SRC_URI:append:hoki = " \
    file://0007-pcm_native-guard-pm_qos_remove_request-with-active-.patch \
    file://wakelock.h \
"

do_configure:prepend:hoki() {
    install -m 644 -D ${UNPACKDIR}/wakelock.h ${S}/include/linux/wakelock.h
}
