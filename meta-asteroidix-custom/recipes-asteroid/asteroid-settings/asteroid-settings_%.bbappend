FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add toggle for Bluetooth Internet Sharing in Settings > Bluetooth
SRC_URI:append = " file://0001-add-internet-sharing-toggle.patch"

# Add System Update page to Settings
SRC_URI:append = " file://0002-add-software-update-page.patch"

RDEPENDS:${PN} += "nemo-qml-plugin-configuration nemo-qml-plugin-dbus"
