# aurora, eos, solios, and seluna flashable boot artifacts
do_image_complete[depends] += "${@bb.utils.contains_any('MACHINE', ['eos', 'solios', 'seluna'], 'aurora-boot-images:do_build', '', d)}"
