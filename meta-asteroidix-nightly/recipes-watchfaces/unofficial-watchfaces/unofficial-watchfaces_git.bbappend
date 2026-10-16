SRC_URI = "git://github.com/AsteroidOS/unofficial-watchfaces.git;protocol=https;branch=master"
SRCREV = "2d8247c28262ba686f49a873beba4d6bff4183c1"

S = "${WORKDIR}/git"

# Disable dynamic package-feed sub-recipe build dependencies for offline build compatibility
do_build[depends] = ""
WATCHFACES = ""

do_configure[noexec] = "1"
do_compile[noexec] = "1"

FILES:${PN} = "${datadir}/asteroid-launcher/ ${datadir}/fonts/"

do_install() {
    install -d ${D}${datadir}/asteroid-launcher/watchfaces
    install -d ${D}${datadir}/asteroid-launcher/watchfaces-img
    install -d ${D}${datadir}/fonts

    # Install common logo
    if [ -f "${S}/logo-45degree/usr/share/asteroid-launcher/watchfaces-img/asteroid-logo.svg" ]; then
        cp -f "${S}/logo-45degree/usr/share/asteroid-launcher/watchfaces-img/asteroid-logo.svg" "${D}${datadir}/asteroid-launcher/watchfaces-img/"
    fi

    # Install all watchface QML files, preview assets, and fonts
    for dir in ${S}/*/; do
        if [ -d "$dir/usr/share" ]; then
            cp -rf "$dir/usr/share/"* "${D}${datadir}/"
        fi
    done

    chmod -R u+w,a+rX ${D}${datadir}
}
