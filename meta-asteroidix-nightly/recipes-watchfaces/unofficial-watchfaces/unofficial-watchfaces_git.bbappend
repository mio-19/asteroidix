SRC_URI = "git://github.com/AsteroidOS/unofficial-watchfaces.git;protocol=https;branch=master"
SRCREV = "2d8247c28262ba686f49a873beba4d6bff4183c1"

# Disable dynamic package-feed sub-recipe build dependencies for offline build compatibility
do_build[depends] = ""
WATCHFACES = ""

do_configure[noexec] = "1"
do_compile[noexec] = "1"

FILES:${PN} = "${datadir}/asteroid-launcher/"

do_install() {
    install -d ${D}${datadir}/asteroid-launcher/watchfaces
    install -d ${D}${datadir}/asteroid-launcher/watchfaces-img

    # Install all watchface QML files and preview assets (fonts are provided by ttf-asteroid-fonts)
    for dir in ${S}/*/; do
        if [ -d "$dir/usr/share/asteroid-launcher" ]; then
            cp -rf "$dir/usr/share/asteroid-launcher/"* "${D}${datadir}/asteroid-launcher/"
        fi
    done

    # Remove files that are already provided by asteroid-launcher
    rm -f ${D}${datadir}/asteroid-launcher/watchfaces-img/asteroid-logo.svg
    rm -f ${D}${datadir}/asteroid-launcher/watchfaces/weathericons.js

    chmod -R u+w,a+rX ${D}${datadir}
}
