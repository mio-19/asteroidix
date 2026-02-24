# Nix sandboxes do not allow setting setuid bits or chown in native installs.
EXTRA_OECONF:append:class-native = " --disable-makeinstall-chown --disable-makeinstall-setuid"
EXTRA_OEMAKE:append:class-native = " suidperms=0755"

do_install:prepend:class-native() {
    # Some util-linux install targets hardcode 4755 regardless of suidperms.
    find ${B} -name Makefile -type f -print0 \
      | xargs -0 sed -i -e 's/chmod[[:space:]]\+4755/chmod 0755/g'
}
