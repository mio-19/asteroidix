FILESEXTRAPATHS:prepend := "${THISDIR}/linux-hoki:${THISDIR}/files:"

SRC_URI:append:hoki = " \
    file://0007-pcm_native-guard-pm_qos_remove_request-with-active-.patch \
    file://wakelock.h \
    file://bt-pan.cfg \
"

do_configure:prepend:hoki() {
    install -m 644 -D ${UNPACKDIR}/wakelock.h ${S}/include/linux/wakelock.h

    if [ -f "${UNPACKDIR}/defconfig" ]; then
        install -m 644 -D ${UNPACKDIR}/defconfig ${WORKDIR}/defconfig
    fi

    # Enable Bluetooth BR/EDR, BNEP (PAN tethering), RFCOMM, HIDP, and LE
    for cfg in "${UNPACKDIR}/defconfig" "${WORKDIR}/defconfig"; do
        if [ -f "$cfg" ]; then
            sed -i 's/# CONFIG_BT_BREDR is not set/CONFIG_BT_BREDR=y/' "$cfg"
            sed -i 's/# CONFIG_BT_LE is not set/CONFIG_BT_LE=y/' "$cfg"
            cat >> "$cfg" << 'EOF'
CONFIG_BT_RFCOMM=y
CONFIG_BT_RFCOMM_TTY=y
CONFIG_BT_BNEP=y
CONFIG_BT_BNEP_MC_FILTER=y
CONFIG_BT_BNEP_PROTO_FILTER=y
CONFIG_BT_HIDP=y
EOF
        fi
    done
}
