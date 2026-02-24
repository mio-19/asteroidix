{
  description = "asteroidix: build AsteroidOS with a robotnix-like Nix module interface";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: f system);
    in
    {
      lib = import ./lib { inherit nixpkgs; };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          systemConfig = self.lib.asteroidixSystem {
            inherit system;
            configuration = {
              machine = "dory";
            };
          };
        in
        {
          default = systemConfig.image;
          image = systemConfig.image;
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-rfc-style);
    };
}
