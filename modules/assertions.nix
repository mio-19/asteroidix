{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    assertions = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            assertion = mkOption {
              type = types.bool;
              description = "Whether the assertion condition is met.";
            };
            message = mkOption {
              type = types.str;
              description = "Explanation of why the assertion failed.";
            };
          };
        }
      );
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
