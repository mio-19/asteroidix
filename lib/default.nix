{ nixpkgs }:

{
  asteroidixSystem =
    {
      configuration ? null,
      modules ? [ ],
      system ? null,
      pkgs ? if system != null then nixpkgs.legacyPackages.${system} else import nixpkgs { },
      lib ? pkgs.lib,
    }:
    import ../default.nix {
      inherit
        configuration
        modules
        pkgs
        lib
        ;
    };

  asteroidixSource =
    {
      system ? null,
      pkgs ? if system != null then nixpkgs.legacyPackages.${system} else import nixpkgs { },
      variant ? "nightly-patched",
    }:
    pkgs.callPackage ./mk-source.nix { } {
      inherit variant;
    };

  mkAsteroidSource = pkgs: variant: pkgs.callPackage ./mk-source.nix { } { inherit variant; };
}
