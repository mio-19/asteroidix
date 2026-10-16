FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Every nightly-patched machine gets find phone. Official builds omit this patch.
SRC_URI:append = "${@' file://0001-add-find-phone-service.patch' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"
