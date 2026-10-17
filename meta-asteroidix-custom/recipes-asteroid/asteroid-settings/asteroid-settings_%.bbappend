FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add toggle for Bluetooth Internet Sharing in Settings > Bluetooth
SRC_URI:append = " file://0001-add-internet-sharing-toggle.patch"
RDEPENDS:${PN} += "nemo-qml-plugin-configuration"
