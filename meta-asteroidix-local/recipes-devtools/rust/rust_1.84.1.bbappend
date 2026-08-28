# rust-snapshot rustc/cargo link against libz; Nix sandboxes lack host libz on LD_LIBRARY_PATH.
DEPENDS:append:class-native = " zlib-native chrpath-native"

rust_native_libz_fixup() {
    snapshot_lib="${WORKDIR}/rust-snapshot/lib"
    install -d "${snapshot_lib}"

    for search in \
        "${RECIPE_SYSROOT_NATIVE}${libdir_native}" \
        "${RECIPE_SYSROOT_NATIVE}${base_libdir_native}" \
        "${RECIPE_SYSROOT_NATIVE}/usr/lib64" \
        "${RECIPE_SYSROOT_NATIVE}/lib64"; do
        if ls "${search}"/libz.so* >/dev/null 2>&1; then
            cp -a "${search}"/libz.so* "${snapshot_lib}/"
            break
        fi
    done

    export LD_LIBRARY_PATH="${snapshot_lib}:${RECIPE_SYSROOT_NATIVE}${libdir_native}:${RECIPE_SYSROOT_NATIVE}${base_libdir_native}:${LD_LIBRARY_PATH}"

    for bin in cargo rustc rustdoc; do
        if [ -x "${WORKDIR}/rust-snapshot/bin/$bin" ]; then
            chrpath -r "\$ORIGIN/../lib" "${WORKDIR}/rust-snapshot/bin/$bin" 2>/dev/null || true
        fi
    done
}

do_rust_setup_snapshot:append:class-native() {
    rust_native_libz_fixup
}

rust_runx:prepend:class-native() {
    rust_native_libz_fixup
}
