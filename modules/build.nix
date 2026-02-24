{
  config,
  pkgs,
  lib,
  ...
}:

let
  mkBblayers = pkgs.writeShellScript "asteroidix-write-bblayers.sh" ''
    set -euo pipefail

    mkdir -p "${config.buildDir}/conf"

    cat > "${config.buildDir}/conf/bblayers.conf" <<'EOC'
    BBPATH = "''${TOPDIR}"
    SRCDIR = "''${@os.path.abspath(os.path.join("''${TOPDIR}", "../src/"))}"

    BBLAYERS = " \
    EOC

    ${lib.concatMapStringsSep "\n" (
      l: ''echo "  \''${SRCDIR}/${l} \\" >> "${config.buildDir}/conf/bblayers.conf"''
    ) config.layerConfs}

    if [ -d src/meta-smartwatch ]; then
      while IFS= read -r layer; do
        rel="''${layer#src/}"
        if ! grep -q "''${rel}" "${config.buildDir}/conf/bblayers.conf"; then
          echo "  \''${SRCDIR}/''${rel} \\" >> "${config.buildDir}/conf/bblayers.conf"
        fi
      done < <(find src/meta-smartwatch -mindepth 1 -type d -name '*meta-*' | sort)
    fi

    echo '"' >> "${config.buildDir}/conf/bblayers.conf"
  '';

  mkBuildBody =
    {
      enablePrefetchMirror,
      localConfExtra ? "",
      runBitbake,
    }:
    ''
      set -euo pipefail

      export HOME="$PWD/home"
      mkdir -p "$HOME"

      source ${config.build.unpackScript}

      mkdir -p ${config.buildDir}/conf
      cat > ${config.buildDir}/conf/local.conf <<'EOC'
      ${config.localConf}
      ${localConfExtra}
      ${lib.optionalString enablePrefetchMirror ''
        DL_DIR = "''${TOPDIR}/downloads"
        BB_GENERATE_MIRROR_TARBALLS = "1"
        SOURCE_MIRROR_URL = "file://''${TOPDIR}/downloads"
        INHERIT += "own-mirrors"
        BB_FETCH_PREMIRRORONLY = "1"
      ''}
      EOC

      ${mkBblayers}

      ${lib.optionalString enablePrefetchMirror ''
        mkdir -p ${config.buildDir}/downloads
        mkdir -p ${config.buildDir}/cache
        cp -a ${config.build.prefetchedSources}/downloads/. ${config.buildDir}/downloads/
        if [ -d ${config.build.prefetchedSources}/cache ]; then
          cp -a ${config.build.prefetchedSources}/cache/. ${config.buildDir}/cache/
        fi
        chmod -R u+w ${config.buildDir}/downloads || true
        chmod -R u+w ${config.buildDir}/cache || true
      ''}

      asteroidix-build <<'EOS'
      set -eo pipefail
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      cd src/oe-core
      . ./oe-init-build-env ../../${config.buildDir} > /dev/null
      export MACHINE=${config.machine}
      ${runBitbake}
      EOS
    '';
in
{
  config = {
    assertions = [
      {
        assertion = (!config.prefetch.enable) || (config.prefetch.hash != null);
        message = "Set `prefetch.hash` when `prefetch.enable = true` (use lib.fakeHash first to discover).";
      }
    ];

    build = rec {
      env = pkgs.buildFHSEnv {
        name = "asteroidix-build";
        targetPkgs = _pkgs: config.envPackages;
        runScript = "bash";
      };

      prefetchedSources =
        if !config.prefetch.enable then
          null
        else
          pkgs.stdenvNoCC.mkDerivation {
            name = "asteroidix-prefetch-${config.machine}";
            srcs = [ ];
            dontUnpack = true;
            dontFixup = true;
            nativeBuildInputs = [ env ];

            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = config.prefetch.hash;

            buildPhase = mkBuildBody {
              enablePrefetchMirror = false;
              localConfExtra = ''
                BB_NO_NETWORK = "0"
                PREMIRRORS:prepend = " \
                https?://ftp.gnu.org/gnu/(.*) https://downloads.yoctoproject.org/mirror/sources/ \
                https?://docbook.org/xml/(.*) https://downloads.yoctoproject.org/mirror/sources/ \
                "
                BB_FETCH_PREMIRRORONLY = "0"
                FETCHCMD_wget = "/usr/bin/env wget --tries=1 --timeout=20 --passive-ftp --no-check-certificate"
              '';
              runBitbake = "bitbake --runall=fetch ${config.imageName}";
            };

            installPhase = ''
              set -euo pipefail
              mkdir -p "$out/downloads" "$out/cache"
              cp -rL ${config.buildDir}/downloads/. "$out/downloads/"
              if [ -d ${config.buildDir}/cache ]; then
                cp -rL ${config.buildDir}/cache/. "$out/cache/"
              fi
              find "$out" -type l -lname '/nix/store/*' -delete || true
              find "$out" -path '*/hooks/*' -type f -delete || true
              find "$out" -path '*/objects/info/alternates' -type f -delete || true
              find "$out" -type f -exec ${pkgs.removeReferencesTo}/bin/remove-references-to \
                -t ${pkgs.bash} \
                -t ${pkgs.bashInteractive} \
                -t ${pkgs.perl} \
                '{}' +
            '';
          };

      image = pkgs.stdenvNoCC.mkDerivation {
        name = "asteroidix-${config.machine}";
        srcs = [ ];
        dontUnpack = true;
        nativeBuildInputs = [ env ];

        buildPhase = mkBuildBody {
          enablePrefetchMirror = config.prefetch.enable;
          localConfExtra = "";
          runBitbake = "bitbake ${config.imageName}";
        };

        installPhase = ''
          set -euo pipefail

          deployDir="${config.buildDir}/tmp/deploy/images/${config.machine}"
          if [ ! -d "$deployDir" ]; then
            echo "Expected output directory missing: $deployDir"
            exit 1
          fi

          mkdir -p "$out/images"
          cp --reflink=auto -r "$deployDir"/* "$out/images/"
        '';
      };

      imagesDir = "${image}/images";

      debugBuildScript = pkgs.writeShellScript "asteroidix-debug-build.sh" ''
        set -euo pipefail
        export MACHINE=${config.machine}
        ${env}/bin/asteroidix-build
      '';
    };
  };
}
