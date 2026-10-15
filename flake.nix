{
  description = "asteroidix: build AsteroidOS with a robotnix-like Nix module interface";

  inputs = {
    nixpkgs.url = "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f system);

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

      configurationsByVariant = forAllSystems (
        system: lib.genAttrs variants (mkAsteroidixConfigurations system)
      );
    in
    {
      lib = import ./lib { inherit nixpkgs; };

      # Default is mio's nightly hoki image.
      asteroidixConfigurations = configurationsByVariant.x86_64-linux.nightly-patched;
      asteroidixConfigurationsByVariant = configurationsByVariant;
      asteroidixConfigurationsBySystem = forAllSystems (
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
          update-prefetch-lock = {
            type = "app";
            program = lib.getExe updatePrefetchLock;
          };
          update-layers = {
            type = "app";
            program = lib.getExe updateLayers;
          };
          push-app = {
            type = "app";
            program = lib.getExe pushApp;
          };
          setup-watch-ssh = {
            type = "app";
            program = lib.getExe setupWatchSsh;
          };
        }
      );

      packages = forAllSystems (
        system:
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
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
