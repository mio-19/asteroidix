FILESEXTRAPATHS:prepend := "${THISDIR}/linux-hoki:${THISDIR}/files:"

SRC_URI:append:hoki = " \
    file://0007-pcm_native-guard-pm_qos_remove_request-with-active-.patch \
    file://0008-fossil-hoki-hardened-security-patches.patch \
    file://wakelock.h \
    file://bt-pan.cfg \
    file://security.cfg \
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

    # Enable kernel security hardening mitigations (GrapheneOS / linux-hardened)
    for cfg in "${UNPACKDIR}/defconfig" "${WORKDIR}/defconfig"; do
        if [ -f "$cfg" ]; then
            sed -i 's/# CONFIG_SLAB_FREELIST_HARDENED is not set/CONFIG_SLAB_FREELIST_HARDENED=y/' "$cfg"
            sed -i 's/# CONFIG_REFCOUNT_FULL is not set/CONFIG_REFCOUNT_FULL=y/' "$cfg"
            sed -i 's/# CONFIG_SECURITY_DMESG_RESTRICT is not set/CONFIG_SECURITY_DMESG_RESTRICT=y/' "$cfg"
            sed -i 's/# CONFIG_SECURITY_YAMA is not set/CONFIG_SECURITY_YAMA=y/' "$cfg"
            cat >> "$cfg" << 'EOF'
CONFIG_SLAB_FREELIST_HARDENED=y
CONFIG_SLAB_FREELIST_RANDOM=y
CONFIG_HARDENED_USERCOPY=y
CONFIG_HARDENED_USERCOPY_PAGESPAN=y
CONFIG_BUG_ON_DATA_CORRUPTION=y
CONFIG_REFCOUNT_FULL=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_SECURITY_DMESG_RESTRICT=y
CONFIG_SECURITY_TIOCSTI_RESTRICT=y
CONFIG_SECURITY_PERF_EVENTS_RESTRICT=y
CONFIG_BPF_UNPRIV_DEFAULT_OFF=y
CONFIG_SYN_COOKIES=y
EOF
        fi
    done
}
