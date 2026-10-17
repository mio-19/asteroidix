FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-compositor-host-the-virtual-keyboard-and-fit-it-to-r.patch \
    file://virtualkeyboard.conf \
"

DEPENDS:append = " qtvirtualkeyboard"
RDEPENDS:${PN}:append = " qtvirtualkeyboard qtvirtualkeyboard-plugins qtvirtualkeyboard-qmlplugins asteroid-virtualkeyboard"

do_install:append() {
    install -d ${D}/var/lib/environment/compositor
    CFG_SRC="${UNPACKDIR}/virtualkeyboard.conf"
    if [ ! -f "$CFG_SRC" ]; then
        CFG_SRC="${WORKDIR}/virtualkeyboard.conf"
    fi
    install -m 0644 "$CFG_SRC" ${D}/var/lib/environment/compositor/virtualkeyboard.conf
}

FILES:${PN} += "/var/lib/environment/compositor/virtualkeyboard.conf"
