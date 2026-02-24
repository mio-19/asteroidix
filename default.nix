{
  configuration,
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  inherit (lib) mkOption types;

  finalPkgs = pkgs.appendOverlays config.nixpkgs.overlays;

  eval = lib.evalModules {
    modules = [
      (
        {
          config,
          ...
        }:
        {
          options.nixpkgs.overlays = mkOption {
            default = [ ];
            type = types.listOf types.unspecified;
            description = "Nixpkgs overlays used while evaluating asteroidix.";
          };

          config = {
            _module.args = {
              pkgs = finalPkgs;
              inherit lib;
            };
          };
        }
      )
      configuration
      ./modules/assertions.nix
      ./modules/base.nix
      ./modules/source.nix
      ./modules/asteroidos.nix
      ./modules/build.nix
    ];
  };

  failedAssertions = map (x: x.message) (lib.filter (x: !x.assertion) eval.config.assertions);

  config =
    if failedAssertions != [ ] then
      throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else
      lib.showWarnings eval.config.warnings eval.config;
in
{
  inherit (eval) options;
  inherit config finalPkgs;

  inherit (config.build)
    image
    imagesDir
    prefetchedSources
    debugBuildScript
    ;
}
