# Nix sandboxes do not allow setting setuid bits or chown in native installs.
#EXTRA_OECONF:append:class-native = " --disable-makeinstall-chown --disable-makeinstall-setuid"
EXTRA_OEMAKE:append:class-native = " suidperms=0755"
