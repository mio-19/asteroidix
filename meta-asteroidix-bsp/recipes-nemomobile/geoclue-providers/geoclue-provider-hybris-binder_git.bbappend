# HOKI FIX: drop setuid-root bit (04755 -> 0755) to prevent glibc/D-Bus from
# stripping DBUS_SESSION_BUS_ADDRESS on startup, which crashes geoclue-hybris
# with qFatal("Failed to register object").
do_install:append() {
    chmod 0755 ${D}/usr/libexec/geoclue-hybris
}
