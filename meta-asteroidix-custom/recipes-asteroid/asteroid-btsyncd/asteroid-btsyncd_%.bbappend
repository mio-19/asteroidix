FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Every nightly-patched machine gets find phone and companion app bridge. Official builds omit this patch.
SRC_URI:append = "${@' file://0001-add-find-phone-service.patch file://0002-add-companion-app-bridge-service.patch' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

