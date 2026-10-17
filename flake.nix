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
            updatePrefetchLock
            updateLayers
            pushApp
            setupWatchSsh
            ;
          run-emulator = emulator;
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
        // linuxPackages
        // (lib.optionalAttrs (!isLinux) {
          default = tools.emulator;
        })
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
