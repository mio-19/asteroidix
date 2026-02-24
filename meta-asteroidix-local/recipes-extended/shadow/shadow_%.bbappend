# Nix sandboxes disallow setting setuid bits during do_install for native tools.
EXTRA_OEMAKE:append:class-native = " suidperms=0755"
