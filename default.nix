{
  configuration ? null,
  modules ? [ ],
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  inherit (lib) mkOption types;

  finalPkgs =
    if eval.config.nixpkgs.overlays == [ ] then
      pkgs
    else
      pkgs.appendOverlays eval.config.nixpkgs.overlays;

  extraModules =
    (
      if configuration == null then
        [ ]
      else if builtins.isList configuration then
        configuration
      else
        [ configuration ]
    )
    ++ modules;

  eval = lib.evalModules {
    modules = [
      ({
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
      })
      ./modules
    ]
    ++ extraModules;
  };

  failedAssertions = map (x: x.message) (lib.filter (x: !x.assertion) eval.config.assertions);

  config =
    if failedAssertions != [ ] then
      throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else
      lib.showWarnings eval.config.warnings eval.config;
in
{
  inherit (eval) options extendModules;
  inherit config;
  pkgs = finalPkgs;
  finalPkgs = finalPkgs; # Backwards-compatible alias

  inherit (config.build)
    image
    imagesDir
    packagesDir
    prefetchedSources
    debugBuildScript
    source
    sourceTree
    ;

  # robotnix-compatible alias
  img = config.build.image;
}
