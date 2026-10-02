{
  config,
  pkgs,
  lib,
  ...
}:

let
  layers = import ./layers.nix;

  supportedMachines = [
    "anthias"
    "aurora"
    "bass"
    "beluga"
    "catfish"
    "dory"
    "emulator"
    "firefish"
    "harmony"
    "hoki"
    "inharmony"
    "koi"
    "lenok"
    "medaka"
    "minnow"
    "mooneye"
    "narwhal"
    "nemo"
    "pike"
    "ray"
    "rinato"
    "rubyfish"
    "sawfish"
    "skipjack"
    "smelt"
    "sparrow"
    "sparrow-mainline"
    "sprat"
    "sturgeon"
    "swift"
    "tetra"
    "triggerfish"
    "wren"
  ];
in
{
  options.asteroidos.supportedMachines = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = supportedMachines;
    readOnly = true;
    description = "Machine values from AsteroidOS prepare-build.sh.";
  };

  config = {
    assertions = [
      {
        assertion = config.machine != null;
        message = "Set `machine` (for example `dory`) to select an AsteroidOS watch target.";
      }
      {
        assertion = config.machine == null || builtins.elem config.machine supportedMachines;
        message = "Unsupported machine `${toString config.machine}`. See `options.asteroidos.supportedMachines`.";
      }
    ];

    layerConfs = [
      "meta-asteroidix-local"
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
    ];

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

    source.dirs = {
      meta-asteroidix-local = {
        relpath = "src/meta-asteroidix-local";
        src = ../meta-asteroidix-local;
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
