{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkIf
    mkOption
    types
    ;
  prefetchLocks = builtins.fromJSON (builtins.readFile ../prefetch-lock.json);
in
{
  options = {
    variant = mkOption {
      type = types.enum [
        "nightly-official"
        "nightly-patched"
        "stable-official"
        "stable-patched"
      ];
      default = "nightly-patched";
      description = ''
        Which image to build.
        `nightly-*` follows AsteroidOS 2.2-nightly (Whinlatter / Qt 6).
        `stable-*` follows AsteroidOS 2.1 (git branch 2.0, Walnascar / Qt 5).
        `*-official` stays on that branch's prepare-build.sh layers.
        `*-patched` also applies mio's Nix sandbox fixes. Find phone is part of `nightly-patched` for hoki.
      '';
    };

    channel = mkOption {
      type = types.enum [
        "nightly"
        "stable"
      ];
      readOnly = true;
      description = "AsteroidOS branch selected by `variant`.";
    };

    flavor = mkOption {
      type = types.enum [
        "official"
        "patched"
      ];
      readOnly = true;
      description = "Whether mio's patches are applied. Selected by `variant`.";
    };

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
      default = "";
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

  config = {
    channel = if lib.hasPrefix "stable-" config.variant then "stable" else "nightly";
    flavor = if lib.hasSuffix "-patched" config.variant then "patched" else "official";

    # Shared by every variant. Upstream local.conf is only DISTRO and
    # PACKAGE_CLASSES; these three lines are the Nix sandbox (offline BitBake).
    localConf = ''
      DISTRO = "asteroid"
      PACKAGE_CLASSES = "package_ipk"
      BB_NO_NETWORK = "1"
      BB_SRCREV_POLICY = "cache"
      CONNECTIVITY_CHECK_URIS = ""
    '';

    prefetch = mkIf (config.machine != null) (
      let
        variantLocks = prefetchLocks.${config.variant} or { };
      in
      {
        hash = mkDefault (variantLocks.${config.machine} or null);
        enable = mkDefault (config.prefetch.hash != null);
      }
    );
  };
}
