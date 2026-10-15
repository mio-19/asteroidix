# Every nightly-patched machine gets find phone. Official builds omit this package.
IMAGE_INSTALL:append = "${@' asteroid-findphone' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Hardware enablement for Fossil Gen 6 (hoki): audio, wlan, gnss
IMAGE_INSTALL:append:hoki = " \
    audio-firmware-hoki \
    audio-mixer-fix-hoki \
    tfa98xx-firmware-hoki \
    linux-wlan-modules-hoki \
    wlan-firmware-hoki \
    gnss-service-hoki \
"

# aurora, eos, solios, and seluna flashable boot artifacts
do_image_complete[depends] += "${@bb.utils.contains_any('MACHINE', ['eos', 'solios', 'seluna'], 'aurora-boot-images:do_build', '', d)}"
