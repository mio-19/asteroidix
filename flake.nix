{
  description = "asteroidix: build AsteroidOS with a robotnix-like Nix module interface";

  inputs = {
    nixpkgs.url = "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      allSystems = linuxSystems ++ darwinSystems;

      forAllSystems = f: lib.genAttrs allSystems (system: f system);
      forLinuxSystems = f: lib.genAttrs linuxSystems (system: f system);

      defaultMachine = "hoki";
      channelConfigs = import ./configs.nix { inherit lib; };

      variants = [
        "nightly-official"
        "nightly-patched"
        "stable-official"
        "stable-patched"
      ];

      channelOf = variant: if lib.hasPrefix "stable-" variant then "stable" else "nightly";

      mkAsteroidixConfigurations =
        system: variant:
        lib.mapAttrs (
          _: configuration:
          self.lib.asteroidixSystem {
            inherit system;
            configuration = configuration // {
              inherit variant;
            };
          }
        ) channelConfigs.configurations.${channelOf variant};

      configurationsByVariant = forLinuxSystems (
        system: lib.genAttrs variants (mkAsteroidixConfigurations system)
      );

      mkTools =
        pkgs:
        let
          emulator = pkgs.writeShellApplication {
            name = "emulator";
            runtimeInputs = with pkgs; [
              coreutils
              curl
              findutils
              qemu
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/run-emulator.sh} "$@"
            '';
          };
          emulatorAarch64 = pkgs.writeShellApplication {
            name = "emulator-aarch64";
            runtimeInputs = with pkgs; [
              coreutils
              curl
              findutils
              qemu
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/run-emulator-aarch64.sh} "$@"
            '';
          };
          updatePrefetchLock = pkgs.writeShellApplication {
            name = "update-prefetch-lock";
            runtimeInputs = with pkgs; [
              coreutils
              gnused
              git
              nix
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/update-prefetch-lock.sh} "$@"
            '';
          };
          updateLayers = pkgs.writeShellApplication {
            name = "update-layers";
            runtimeInputs = with pkgs; [
              coreutils
              git
              gnused
              gawk
              jq
              nix-prefetch-github
              nix-prefetch-git
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/update-layers.sh} "$@"
            '';
          };
          pushApp = pkgs.writeShellApplication {
            name = "push-app";
            runtimeInputs = with pkgs; [
              coreutils
              findutils
              android-tools
              openssh
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/push-app.sh} "$@"
            '';
          };
          setupWatchSsh = pkgs.writeShellApplication {
            name = "setup-watch-ssh";
            runtimeInputs = with pkgs; [
              coreutils
              android-tools
              openssh
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/setup-watch-ssh.sh} "$@"
            '';
          };
        in
        {
          inherit
            emulator
            emulatorAarch64
            updatePrefetchLock
            updateLayers
            pushApp
            setupWatchSsh
            ;
          run-emulator = emulator;
          "emulator-aarch64" = emulatorAarch64;
          "run-emulator-aarch64" = emulatorAarch64;
          "update-prefetch-lock" = updatePrefetchLock;
          "update-layers" = updateLayers;
          "push-app" = pushApp;
          "setup-watch-ssh" = setupWatchSsh;
        };
    in
    {
      lib = import ./lib { inherit nixpkgs; };

      # Default is mio's nightly hoki image.
      asteroidixConfigurations = configurationsByVariant.x86_64-linux.nightly-patched;
      asteroidixConfigurationsByVariant = configurationsByVariant;
      asteroidixConfigurationsBySystem = forLinuxSystems (
        system: configurationsByVariant.${system}.nightly-patched
      );

      asteroidixModules.default = ./modules;
      asteroidixModule = ./modules;

      templates.default = {
        path = ./template;
        description = "A basic asteroidix configuration flake";
      };

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tools = mkTools pkgs;
        in
        {
          default = {
            type = "app";
            program = lib.getExe tools.emulator;
          };
          emulator = {
            type = "app";
            program = lib.getExe tools.emulator;
          };
          run-emulator = {
            type = "app";
            program = lib.getExe tools.emulator;
          };
          emulator-aarch64 = {
            type = "app";
            program = lib.getExe tools.emulatorAarch64;
          };
          run-emulator-aarch64 = {
            type = "app";
            program = lib.getExe tools.emulatorAarch64;
          };
          update-prefetch-lock = {
            type = "app";
            program = lib.getExe tools.updatePrefetchLock;
          };
          update-layers = {
            type = "app";
            program = lib.getExe tools.updateLayers;
          };
          push-app = {
            type = "app";
            program = lib.getExe tools.pushApp;
          };
          setup-watch-ssh = {
            type = "app";
            program = lib.getExe tools.setupWatchSsh;
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          isLinux = lib.elem system linuxSystems;
          tools = mkTools pkgs;
          mkSource = variant: self.lib.asteroidixSource { inherit system variant; };

          sourcePackages = {
            source-nightly-official = mkSource "nightly-official";
            source-nightly-patched = mkSource "nightly-patched";
            source-stable-official = mkSource "stable-official";
            source-stable-patched = mkSource "stable-patched";

            nightly-official-source = mkSource "nightly-official";
            nightly-patched-source = mkSource "nightly-patched";
            stable-official-source = mkSource "stable-official";
            stable-patched-source = mkSource "stable-patched";

            nightly-official-src = mkSource "nightly-official";
            nightly-patched-src = mkSource "nightly-patched";
            stable-official-src = mkSource "stable-official";
            stable-patched-src = mkSource "stable-patched";

            src-nightly-official = mkSource "nightly-official";
            src-nightly-patched = mkSource "nightly-patched";
            src-stable-official = mkSource "stable-official";
            src-stable-patched = mkSource "stable-patched";

            source = mkSource "nightly-patched";
            src = mkSource "nightly-patched";
            source-official = mkSource "nightly-official";
            source-patched = mkSource "nightly-patched";
            official-source = mkSource "nightly-official";
            patched-source = mkSource "nightly-patched";
          };

          linuxPackages =
            if !isLinux then
              { }
            else
              let
                byVariant = configurationsByVariant.${system};

                variantImages = lib.concatMapAttrs (
                  variant: configurations:
                  lib.mapAttrs' (
                    machine: asteroid: lib.nameValuePair "${machine}-${variant}-img" asteroid.img
                  ) configurations
                ) byVariant;

                # Short names stay on nightly, the branch the previous two builds used.
                nightlyAliases =
                  lib.concatMapAttrs
                    (
                      flavor: configurations:
                      lib.mapAttrs' (
                        machine: asteroid: lib.nameValuePair "${machine}-${flavor}-img" asteroid.img
                      ) configurations
                    )
                    {
                      official = byVariant.nightly-official;
                      patched = byVariant.nightly-patched;
                    };

                nightlyMachineAliases = lib.mapAttrs' (
                  machine: asteroid: lib.nameValuePair "${machine}-img" asteroid.img
                ) byVariant.nightly-patched;

                nightlyPatchedDefault = byVariant.nightly-patched.${defaultMachine};
                nightlyOfficialDefault = byVariant.nightly-official.${defaultMachine};
              in
              variantImages
              // nightlyAliases
              // nightlyMachineAliases
              // {
                default = nightlyPatchedDefault.img;
                img = nightlyPatchedDefault.img;
                image = nightlyPatchedDefault.image;
                official-img = nightlyOfficialDefault.img;
                patched-img = nightlyPatchedDefault.img;
              };
        in
        tools
        // sourcePackages
        // linuxPackages
        // (lib.optionalAttrs (!isLinux) {
          default = tools.emulator;
        })
      );

      sources = forAllSystems (system: {
        nightly-official = self.lib.asteroidixSource {
          inherit system;
          variant = "nightly-official";
        };
        nightly-patched = self.lib.asteroidixSource {
          inherit system;
          variant = "nightly-patched";
        };
        stable-official = self.lib.asteroidixSource {
          inherit system;
          variant = "stable-official";
        };
        stable-patched = self.lib.asteroidixSource {
          inherit system;
          variant = "stable-patched";
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
