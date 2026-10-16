# Every nightly-patched machine gets find phone. Official builds omit this package.
IMAGE_INSTALL:append = "${@' asteroid-findphone' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Community applications on patched builds
IMAGE_INSTALL:append = "${@' unofficial-watchfaces asteroid-blaster asteroid-dodger asteroid-health asteroid-map asteroid-qmltester asteroid-skedaddle asteroid-weatherfetch' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Hardware enablement for Fossil Gen 6 (hoki): audio, wlan, gnss, spo2 (only on patched variant)
IMAGE_INSTALL:append:hoki = "${@' audio-firmware-hoki audio-mixer-fix-hoki tfa98xx-firmware-hoki linux-wlan-modules-hoki wlan-firmware-hoki gnss-service-hoki asteroid-spo2' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"


# aurora, eos, solios, and seluna flashable boot artifacts
do_image_complete[depends] += "${@bb.utils.contains_any('MACHINE', ['eos', 'solios', 'seluna'], 'aurora-boot-images:do_build', '', d)}"
