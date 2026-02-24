{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    machine = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "AsteroidOS machine codename (for example: dory, rubyfish).";
    };

    imageName = mkOption {
      type = types.str;
      default = "asteroid-image";
      description = "BitBake target image name.";
    };

    buildDir = mkOption {
      type = types.str;
      default = "build";
      description = "Build output directory relative to the derivation workdir.";
    };

    envPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages exposed inside the FHS build environment.";
      internal = true;
    };

    localConf = mkOption {
      type = types.lines;
      default = ''
        DISTRO = "asteroid"
        PACKAGE_CLASSES = "package_ipk"
        BB_NO_NETWORK = "1"
        BB_SRCREV_POLICY = "cache"
        CONNECTIVITY_CHECK_URIS = ""
        ASSUME_PROVIDED:remove = "virtual/crypt-native"
        CFLAGS:append:pn-libxcrypt-native = " -Wno-error"
        PREMIRRORS:append = " \
        https://ftp.gnu.org/gnu/(.*) https://mirrors.kernel.org/gnu/\\1 \
        http://ftp.gnu.org/gnu/(.*) https://mirrors.kernel.org/gnu/\\1 \
        "
      '';
      description = "Contents written to build/conf/local.conf.";
    };

    layerConfs = mkOption {
      type = types.listOf types.str;
      description = "Layer paths inserted into bblayers.conf.";
      default = [ ];
    };

    prefetch = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable fixed-output source prefetch (bitbake fetchall) for offline builds.";
      };

      hash = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Recursive sha256 hash for the prefetched downloads output.";
      };
    };

    build = mkOption {
      type = types.attrs;
      default = { };
      internal = true;
    };
  };
}
