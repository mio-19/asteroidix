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
}
