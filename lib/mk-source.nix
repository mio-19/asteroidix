{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchgit,
}:

{
  variant ? "nightly-patched",
  channel ? (if lib.hasPrefix "stable-" variant then "stable" else "nightly"),
  flavor ? (if lib.hasSuffix "-patched" variant then "patched" else "official"),
  asteroidRepo ? (import ../modules/layers/asteroid.nix).${channel},
  layers ? (import ../modules/layers/${channel}.nix),
  metaAsteroidixCustom ? ../meta-asteroidix-custom,
  metaAsteroidixBsp ? ../meta-asteroidix-bsp,
}:

let
  baseAsteroid = fetchFromGitHub {
    owner = asteroidRepo.owner;
    repo = asteroidRepo.repo;
    rev = asteroidRepo.rev;
    hash = asteroidRepo.hash;
  };

  fetchedLayers = lib.mapAttrs (_: layer: {
    inherit (layer) relpath;
    src =
      if layer ? url then
        fetchgit {
          inherit (layer) url rev hash;
          fetchSubmodules = false;
        }
      else
        fetchFromGitHub {
          inherit (layer)
            owner
            repo
            rev
            hash
            ;
        };
  }) layers;

  customLayers = lib.optionals (flavor == "patched" && channel == "nightly") [
    {
      relpath = "src/meta-asteroidix-custom";
      src = metaAsteroidixCustom;
    }
    {
      relpath = "src/meta-asteroidix-bsp";
      src = metaAsteroidixBsp;
    }
  ];

  # Sort by relpath so parent dirs (like src/oe-core) are copied before subdirs (like src/oe-core/bitbake).
  allLayers = lib.sort (a: b: a.relpath < b.relpath) ((lib.attrValues fetchedLayers) ++ customLayers);
in
stdenvNoCC.mkDerivation {
  name = "asteroidos-source-${variant}";

  dontUnpack = true;
  dontFixup = true;

  meta = with lib; {
    description = "AsteroidOS ${variant} source checkout for official build methods (without Nix build/sandbox patches)";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl2Plus;
    platforms = platforms.all;
  };

  installPhase = ''
        set -euo pipefail

        mkdir -p "$out"
        cp --reflink=auto --no-preserve=ownership,mode -r ${baseAsteroid}/. "$out/"
        chmod -R u+w "$out"

        ${lib.concatMapStringsSep "\n" (layer: ''
          mkdir -p "$out/${layer.relpath}"
          cp --reflink=auto --no-preserve=ownership,mode -r ${layer.src}/. "$out/${layer.relpath}/"
          chmod -R u+w "$out/${layer.relpath}"
        '') allLayers}

        # Add a friendly guard in prepare-build.sh if run directly within the read-only /nix/store
        sed -i '2i \
    if [ ! -w . ]; then\
        echo -e "\\e[91mError: Current directory is read-only (e.g. inside /nix/store).\\e[39m" >&2\
        echo "To build AsteroidOS using the official way, copy this tree to a writable directory first:" >&2\
        echo "  cp -rL \$(pwd) ~/asteroid-build && chmod -R u+w ~/asteroid-build && cd ~/asteroid-build" >&2\
        return 1 2>/dev/null || exit 1\
    fi' "$out/prepare-build.sh"

        ${lib.optionalString (flavor == "patched" && channel == "nightly") ''
          # Add custom and bsp layers to layers_conf in prepare-build.sh
          sed -i '/"meta-virtualization"/a \    "meta-asteroidix-custom"\n    "meta-asteroidix-bsp"' "$out/prepare-build.sh"

          # Expand discover_devices to also discover machines from meta-asteroidix-bsp
          sed -i 's|find src/meta-smartwatch -path|find src/meta-smartwatch src/meta-asteroidix-bsp -path|g' "$out/prepare-build.sh"

          # Configure ASTEROIDIX_PATCHED and Fossil Gen 6 WLAN in local.conf
          sed -i 's|PACKAGE_CLASSES = "package_ipk"|PACKAGE_CLASSES = "package_ipk"\nASTEROIDIX_PATCHED = "1"\nMACHINE_HAS_WLAN:hoki = "true"|g' "$out/prepare-build.sh"
        ''}

        ${lib.optionalString (flavor == "patched" && channel == "stable") ''
          # Configure ASTEROIDIX_PATCHED and Fossil Gen 6 WLAN in local.conf
          sed -i 's|PACKAGE_CLASSES = "package_ipk"|PACKAGE_CLASSES = "package_ipk"\nASTEROIDIX_PATCHED = "1"\nMACHINE_HAS_WLAN:hoki = "true"|g' "$out/prepare-build.sh"
        ''}

        # Validate that prepare-build.sh patches were applied correctly
        grep -q "Error: Current directory is read-only" "$out/prepare-build.sh"
        ${lib.optionalString (flavor == "patched") ''
          grep -q "ASTEROIDIX_PATCHED" "$out/prepare-build.sh"
        ''}
        ${lib.optionalString (flavor == "patched" && channel == "nightly") ''
          grep -q "meta-asteroidix-custom" "$out/prepare-build.sh"
          grep -q "meta-asteroidix-bsp" "$out/prepare-build.sh"
        ''}

        chmod +x "$out/prepare-build.sh"
  '';
}
