SUMMARY = "AsteroidOS Bluetooth Internet Sharing (PAN/NAP) helper"
DESCRIPTION = "Utility and service to connect AsteroidOS to phone Bluetooth internet sharing (PAN/NAP)"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

SRC_URI = " \
    file://asteroid-bt-pan \
    file://asteroid-bt-pan.service \
"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "asteroid-bt-pan.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "python3-core python3-dbus bluez5 iproute2"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/asteroid-bt-pan ${D}${bindir}/asteroid-bt-pan

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/asteroid-bt-pan.service ${D}${systemd_system_unitdir}/asteroid-bt-pan.service
}

FILES:${PN} += "${bindir}/asteroid-bt-pan ${systemd_system_unitdir}/asteroid-bt-pan.service"
