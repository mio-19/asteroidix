FILESEXTRAPATHS:prepend := "${THISDIR}/linux-audio-modules-hoki:"

SRC_URI:append:hoki = " \
    file://0006-fix-codec-subdir-recursion-gated-on-KERNEL_BUILD.patch \
"

EXTRA_OEMAKE:append:hoki = " CONFIG_SND_SOC_ANALOG_CDC=m CONFIG_SND_SOC_DIGITAL_CDC= CONFIG_SND_SOC_DIGITAL_CDC_LEGACY=m KCFLAGS=-Wno-error"

RPROVIDES:${PN} += "kernel-module-audio-analog-cdc kernel-module-audio-digital-cdc"
