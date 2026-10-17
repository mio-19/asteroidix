# Every nightly-patched machine gets find phone, web browser, tack metronome, 2048 game, and beatfork. Official builds omit these packages.
IMAGE_INSTALL:append = "${@' asteroid-findphone asteroid-browser asteroid-tack asteroid-2048 asteroid-beatfork' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Community applications on patched builds
IMAGE_INSTALL:append = "${@' unofficial-watchfaces asteroid-blaster asteroid-dodger asteroid-health asteroid-map asteroid-qmltester asteroid-skedaddle asteroid-weatherfetch' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Hardware enablement for Fossil Gen 6 (hoki): wlan, gnss, spo2 (only on patched variant; speaker & mic are upstream in meta-smartwatch #357)
IMAGE_INSTALL:append:hoki = "${@' linux-wlan-modules-hoki wlan-firmware-hoki gnss-service-hoki asteroid-spo2' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Bluetooth internet sharing (PAN / tethering from phone)
IMAGE_INSTALL:append = "${@' connman-client bluez5-testtools bluez5-noinst-tools python3-dbus asteroid-bt-pan' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# Virtual keyboard, Wayland text-input, Ladybird browser, and librime CJK input method
IMAGE_INSTALL:append = "${@' asteroid-virtualkeyboard qtvirtualkeyboard qtvirtualkeyboard-plugins qtvirtualkeyboard-qmlplugins ladybird marisa librime rime-data qtvirtualkeyboard-librime' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"


