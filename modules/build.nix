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
                cp -a ${config.build.prefetchedSources}/downloads/. ${config.buildDir}/downloads/
                chmod -R u+w ${config.buildDir}/downloads || true

                if [ -f ${config.buildDir}/downloads/autorevs.json ]; then
                  mkdir -p ${config.buildDir}/cache
                  ${pkgs.python3}/bin/python3 -c '
        import pickle, json
        with open("${config.buildDir}/downloads/autorevs.json", "r") as f:
            d = json.load(f)
        with open("${config.buildDir}/cache/local_srcrevisions.dat", "wb") as out:
            pickle.dump([ [d], 1 ], out, -1)
        '
                fi
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
                BB_GENERATE_MIRROR_TARBALLS = "1"
                # Prefer kernel.org's Yocto source mirror (typically faster than
                # downloads.yoctoproject.org). Upstream hosts rate-limit under fetchall.
                PREMIRRORS:prepend = " \
                https?://zlib.net/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://ftp.gnu.org/gnu/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://docbook.org/xml/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://cdn.kernel.org/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://.*/kernel.org/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://cmake.org/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://busybox.net/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://download.savannah.gnu.org/(.*) https://mirrors.kernel.org/yocto-sources/ \
                https?://download.savannah.nongnu.org/(.*) https://mirrors.kernel.org/yocto-sources/ \
                git://sourceware.org/git/glibc.git https://mirrors.kernel.org/yocto-sources/ \
                git://sourceware.org/git/binutils-gdb.git https://mirrors.kernel.org/yocto-sources/ \
                git://salsa.debian.org/iso-codes-team/iso-codes.git https://mirrors.kernel.org/yocto-sources/ \
                git://code.qt.io/qt/.* https://mirrors.kernel.org/yocto-sources/ \
                git://android.googlesource.com/.* https://mirrors.kernel.org/yocto-sources/ \
                git://github.com/.* https://mirrors.kernel.org/yocto-sources/ \
                git://.*/.* https://mirrors.kernel.org/yocto-sources/ \
                "
                BB_FETCH_PREMIRRORONLY = "0"
                # Default bitbake wget is --tries=2 --timeout=100; keep retries healthy
                # and only special-case crates.io User-Agent (returns 403 otherwise).
                FETCHCMD_wget = "${pkgs.writeShellScript "wget-wrapper.sh" ''
                  if [[ "$*" == *"crates.io"* ]]; then
                    exec wget --tries=5 --timeout=100 --passive-ftp --no-check-certificate -U "Bitbake/2.0" "$@"
                  else
                    exec wget --tries=5 --timeout=100 --passive-ftp --no-check-certificate "$@"
                  fi
                ''}"
              '';
              runBitbake = "bitbake --runall=fetch ${config.imageName}";
            };

            installPhase = ''
                            set -euo pipefail
                            mkdir -p "$out/downloads"
                            cp -rL ${config.buildDir}/downloads/. "$out/downloads/"

                            if [ -f ${config.buildDir}/cache/local_srcrevisions.dat ]; then
                              ${pkgs.python3}/bin/python3 -c '
              import pickle, json
              with open("${config.buildDir}/cache/local_srcrevisions.dat", "rb") as f:
                  d = pickle.load(f)
              with open("autorevs.json", "w") as out:
                  json.dump(d[0][0], out, sort_keys=True, separators=(",", ":"))
              '
                              mv autorevs.json "$out/downloads/"
                            fi

                            # Drop non-deterministic / redundant fetcher state. Offline builds use
                            # mirror tarballs + .done markers via own-mirrors; bare git2 clones and
                            # lock files vary between runs and break the fixed-output hash.
                            # Keep .done contents — BitBake stores checksum stamps there.
                            rm -rf "$out/downloads/git2" "$out/downloads/svn" "$out/downloads/cvs"
                            find "$out/downloads" -name '*.lock' -delete || true
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
