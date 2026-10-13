# Nix sandboxes reject setuid during native do_install.
# Upstream already passes --disable-makeinstall-chown. In util-linux 2.41 the
# remaining chmod 4755 hooks are gated by MAKEINSTALL_DO_SETUID, so disabling
# that is enough; there is no suidperms make variable to override.
EXTRA_OECONF:append:class-native = " --disable-makeinstall-setuid"
