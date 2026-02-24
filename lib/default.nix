{ nixpkgs }:

{
  asteroidixSystem =
    {
      configuration,
      system,
      pkgs ? import nixpkgs { inherit system; },
    }:
    import ../default.nix {
      inherit configuration pkgs;
      lib = pkgs.lib;
    };
}
