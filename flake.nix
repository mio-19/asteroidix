{
  description = "asteroidix: build AsteroidOS with a robotnix-like Nix module interface";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

      defaultMachine = "dory";
      machineConfigurations = import ./configs.nix { inherit lib; };

      mkAsteroidixConfigurations =
        system:
        lib.mapAttrs (
          _: configuration:
          self.lib.asteroidixSystem {
            inherit system configuration;
          }
        ) machineConfigurations;
    in
    {
      lib = import ./lib { inherit nixpkgs; };

      asteroidixConfigurations = mkAsteroidixConfigurations "x86_64-linux";
      asteroidixConfigurationsBySystem = forAllSystems mkAsteroidixConfigurations;

      templates.default = {
        path = ./template;
        description = "A basic asteroidix configuration flake";
      };

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          updatePrefetchLock = pkgs.writeShellScriptBin "update-prefetch-lock" ''
            exec env REPO_ROOT="$PWD" ${./scripts/update-prefetch-lock.sh} "$@"
          '';
          updateLayers = pkgs.writeShellApplication {
            name = "update-layers";
            runtimeInputs = with pkgs; [
              coreutils
              git
              gnused
              gawk
              jq
              nix-prefetch-github
            ];
            text = ''
              exec env REPO_ROOT="$PWD" ${./scripts/update-layers.sh} "$@"
            '';
          };
        in
        {
          update-prefetch-lock = {
            type = "app";
            program = "${updatePrefetchLock}/bin/update-prefetch-lock";
          };
          update-layers = {
            type = "app";
            program = "${updateLayers}/bin/update-layers";
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          configurations = mkAsteroidixConfigurations system;
          machineImages = lib.mapAttrs' (
            machine: asteroid: lib.nameValuePair "${machine}-img" asteroid.img
          ) configurations;
          defaultConfiguration = configurations.${defaultMachine};
        in
        machineImages
        // {
          default = defaultConfiguration.img;
          img = defaultConfiguration.img;
          image = defaultConfiguration.image;
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-rfc-style);
    };
}
