# Every nightly-patched machine gets find phone. Official builds omit this package.
IMAGE_INSTALL:append = "${@' asteroid-findphone' if d.getVar('ASTEROIDIX_PATCHED') == '1' else ''}"

# aurora and eos flashable boot artifacts
do_image_complete[depends] += "${@bb.utils.contains('MACHINE', 'eos', 'aurora-boot-images:do_build', '', d)}"
