SUMMARY = "Rime schema configuration and common Chinese input methods"
HOMEPAGE = "https://github.com/rime"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

SRC_URI = " \
    file://default.yaml \
    file://pinyin_simp.schema.yaml \
    file://pinyin_simp.dict.yaml \
    file://luna_pinyin.schema.yaml \
    file://double_pinyin.schema.yaml \
    file://wubi86.schema.yaml \
    file://wubi86.dict.yaml \
    file://stroke.schema.yaml \
    file://stroke.dict.yaml \
"

inherit allarch

do_install() {
    install -d ${D}${datadir}/rime-data
    DATA_SRC="${UNPACKDIR}"
    if [ ! -f "$DATA_SRC/default.yaml" ]; then
        DATA_SRC="${WORKDIR}"
    fi
    install -m 0644 $DATA_SRC/*.yaml ${D}${datadir}/rime-data/
}

FILES:${PN} += "${datadir}/rime-data/"
