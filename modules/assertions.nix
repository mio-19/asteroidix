{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    assertions = mkOption {
      type = types.listOf types.unspecified;
      internal = true;
      default = [ ];
      description = "Assertions that must hold for evaluation to succeed.";
    };

    warnings = mkOption {
      type = types.listOf types.str;
      internal = true;
      default = [ ];
      description = "Evaluation-time warnings.";
    };
  };
}
