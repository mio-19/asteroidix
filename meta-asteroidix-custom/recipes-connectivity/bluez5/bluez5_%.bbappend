FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_install:append() {
    # Upstream AsteroidOS locks BlueZ to ControllerMode = le (BLE-only).
    # Enable dual mode (BLE + BR/EDR) so Classic Bluetooth profiles like
    # Bluetooth PAN (Network Access Point / internet sharing) work simultaneously
    # with BLE sync (asteroid-btsyncd).
    if [ -f ${D}/etc/bluetooth/main.conf ]; then
        sed -i 's/^[#[:space:]]*ControllerMode[[:space:]]*=.*/ControllerMode = dual/' ${D}/etc/bluetooth/main.conf
        if ! grep -q "DiscoverableTimeout" ${D}/etc/bluetooth/main.conf; then
            echo "DiscoverableTimeout = 180" >> ${D}/etc/bluetooth/main.conf
        fi
    fi
}
