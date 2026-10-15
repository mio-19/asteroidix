{
  config,
  pkgs,
  lib,
  ...
}:

let
  layersByChannel = import ./layers.nix;
  layers = layersByChannel.${config.channel};
  machines = (import ../configs.nix { inherit lib; }).machines;
in
{
  options.asteroidos.supportedMachines = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    description = "Machine values from AsteroidOS prepare-build.sh for the selected channel.";
  };

  config = {
    asteroidos.supportedMachines = machines.${config.channel};

    # Recipe and local.conf changes that upstream AsteroidOS does not ship.
    localConf = lib.mkIf (config.flavor == "patched") (
      lib.mkAfter ''
        ASSUME_PROVIDED:remove = "virtual/crypt-native"
        CFLAGS:append:pn-libxcrypt-native = " -Wno-error"
        HOSTTOOLS:append = " convert"
        # Prefer basename mirrors (no capture backrefs — those break URL construction).
        PREMIRRORS:append = " \
        https://ftp.gnu.org/gnu/.* https://mirrors.kernel.org/gnu/ \
        http://ftp.gnu.org/gnu/.* https://mirrors.kernel.org/gnu/ \
        "
        ASTEROIDIX_PATCHED = "1"
        MACHINE_HAS_WLAN:hoki = "true"
      ''
    );

    assertions = [
      {
        assertion = config.machine != null;
        message = "Set `machine` (for example `dory`) to select an AsteroidOS watch target.";
      }
      {
        assertion = config.machine == null || lib.elem config.machine config.asteroidos.supportedMachines;
        message = "Unsupported machine `${toString config.machine}` on `${config.channel}`. See `options.asteroidos.supportedMachines`.";
      }
    ];

    layerConfs =
      lib.optionals
        (
          config.variant == "nightly-patched"
          || (
            config.channel == "nightly"
            && lib.elem config.machine [
              "eos"
              "seluna"
              "solios"
            ]
          )
        )
        [
          "meta-asteroidix-nightly"
        ]
      ++ lib.optionals (config.flavor == "patched") [
        "meta-asteroidix-local"
      ]
      ++ (
        if config.channel == "stable" then
          [
            "meta-qt5"
            "oe-core/meta"
            "meta-asteroid"
            "meta-asteroid-community"
            "meta-openembedded/meta-oe"
            "meta-openembedded/meta-multimedia"
            "meta-openembedded/meta-gnome"
            "meta-openembedded/meta-networking"
            "meta-smartphone/meta-android"
            "meta-openembedded/meta-python"
            "meta-openembedded/meta-filesystems"
          ]
        else
          [
            "meta-qt6"
            "oe-core/meta"
            "meta-asteroid"
            "meta-asteroid-community"
            "meta-openembedded/meta-oe"
            "meta-openembedded/meta-multimedia"
            "meta-openembedded/meta-gnome"
            "meta-openembedded/meta-networking"
            "meta-smartphone/meta-android"
            "meta-openembedded/meta-python"
            "meta-openembedded/meta-filesystems"
            "meta-clang"
            "meta-virtualization"
          ]
      );

    envPackages = with pkgs; [
      bash
      bc
      binutils
      bzip2
      cacert
      chrpath
      cpio
      diffstat
      file
      findutils
      gawk
      gcc
      gnumake
      gnused
      gnugrep
      git
      hostname
      imagemagick
      libxcrypt
      lz4
      ncurses
      patch
      perl
      python3
      rpcsvc-proto
      rsync
      shared-mime-info
      socat
      shadow
      texinfo
      util-linux
      wget
      which
      xz
      zstd
    ];

    source.dirs =
      lib.optionalAttrs (config.flavor == "patched") {
        meta-asteroidix-local = {
          relpath = "src/meta-asteroidix-local";
          src = ../meta-asteroidix-local;
        };
      }
      //
        lib.optionalAttrs
          (
            config.variant == "nightly-patched"
            || (
              config.channel == "nightly"
              && lib.elem config.machine [
                "eos"
                "seluna"
                "solios"
              ]
            )
          )
          {
            meta-asteroidix-nightly = {
              relpath = "src/meta-asteroidix-nightly";
              src = ../meta-asteroidix-nightly;
            };
          }
      // lib.mapAttrs (_: layer: {
        relpath = layer.relpath;
        src =
          if layer ? url then
            pkgs.fetchgit {
              inherit (layer) url rev hash;
              fetchSubmodules = false;
            }
          else
            pkgs.fetchFromGitHub {
              inherit (layer)
                owner
                repo
                rev
                hash
                ;
            };
      }) layers;
  };
}
