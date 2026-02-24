{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkOption
    mkDefault
    mkIf
    types
    ;

  fileModule = types.submodule (
    { ... }:
    {
      options = {
        src = mkOption {
          type = types.str;
          description = "Path relative to this source directory.";
        };

        dest = mkOption {
          type = types.str;
          description = "Path relative to workspace root where file/symlink is created.";
        };
      };
    }
  );

  dirModule =
    let
      _config = config;
    in
    types.submodule (
      { name, config, ... }:
      {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this directory is included in the workspace.";
          };

          relpath = mkOption {
            type = types.str;
            default = name;
            description = "Destination path under the workspace.";
          };

          manifestSrc = mkOption {
            type = types.nullOr types.path;
            default = null;
            internal = true;
            description = "Original source from a manifest/lock import.";
          };

          src = mkOption {
            type = types.path;
            description = "Source directory for this entry.";
            default = pkgs.runCommand "empty-source-dir" { } "mkdir -p $out";
            apply =
              src:
              if config.patches != [ ] || config.postPatch != "" then
                pkgs.runCommand "${builtins.replaceStrings [ "/" ] [ "=" ] config.relpath}-patched"
                  {
                    inherit (config) nativeBuildInputs;
                  }
                  ''
                    cp --reflink=auto --no-preserve=ownership --no-dereference --preserve=links -r ${src}/. $out/
                    chmod -R u+w $out
                    ${lib.concatMapStringsSep "\n" (
                      p: "patch -p1 --no-backup-if-mismatch -d $out < ${p}"
                    ) config.patches}
                    cd $out
                    ${config.postPatch}
                  ''
              else
                src;
          };

          rev = mkOption {
            type = types.nullOr types.str;
            default = null;
            internal = true;
            description = "Optional source revision metadata.";
          };

          groups = mkOption {
            type = types.listOf types.str;
            default = [ ];
            internal = true;
            description = "Optional group metadata for include/exclude filtering.";
          };

          date = mkOption {
            type = types.nullOr types.int;
            default = null;
            internal = true;
            description = "Optional source timestamp metadata.";
          };

          patches = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = "Patches applied to this source directory.";
          };

          postPatch = mkOption {
            type = types.lines;
            default = "";
            description = "Additional shell commands run after applying patches.";
          };

          nativeBuildInputs = mkOption {
            type = types.listOf types.package;
            default = [ ];
            description = "Packages available while applying postPatch.";
          };

          copyfiles = mkOption {
            type = types.listOf fileModule;
            default = [ ];
            description = "Files copied from this source dir into other workspace paths.";
          };

          linkfiles = mkOption {
            type = types.listOf fileModule;
            default = [ ];
            description = "Symlinks created from this source dir into other workspace paths.";
          };

          unpackScript = mkOption {
            type = types.lines;
            internal = true;
            description = "Per-directory unpack commands.";
          };
        };

        config = {
          enable = mkDefault (
            (lib.any (g: lib.elem g config.groups) _config.source.includeGroups)
            || (!(lib.any (g: lib.elem g config.groups) _config.source.excludeGroups))
          );

          src = mkIf (config.manifestSrc != null) (mkDefault config.manifestSrc);

          unpackScript =
            (lib.optionalString config.enable ''
              mkdir -p ${lib.escapeShellArg config.relpath}
              cp --reflink=auto --no-preserve=ownership --no-dereference --preserve=links -r ${config.src}/. ${lib.escapeShellArg config.relpath}/
              chmod -R u+w ${lib.escapeShellArg config.relpath}
            '')
            + (lib.concatMapStringsSep "\n" (c: ''
              mkdir -p "$(dirname ${lib.escapeShellArg c.dest})"
              cp --reflink=auto -f ${lib.escapeShellArg config.relpath}/${lib.escapeShellArg c.src} ${lib.escapeShellArg c.dest}
            '') config.copyfiles)
            + (lib.concatMapStringsSep "\n" (c: ''
              mkdir -p "$(dirname ${lib.escapeShellArg c.dest})"
              if [ ! -e ${lib.escapeShellArg c.dest} ]; then
                ln -s --relative ${lib.escapeShellArg config.relpath}/${lib.escapeShellArg c.src} ${lib.escapeShellArg c.dest}
              fi
            '') config.linkfiles);
        };
      }
    );

  dirsByRelpath = builtins.sort (a: b: a.relpath < b.relpath) (lib.attrValues config.source.dirs);

  unpackScript = pkgs.writeShellScript "asteroidix-unpack.sh" (
    lib.concatStringsSep "\n" (map (d: d.unpackScript) dirsByRelpath)
  );
in
{
  options.source = {
    dirs = mkOption {
      type = types.attrsOf dirModule;
      default = { };
      description = "Workspace source directories, similar to robotnix source.dirs.*.";
    };

    excludeGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Exclude source dirs that match these groups (unless explicitly included).";
    };

    includeGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Always include source dirs that match these groups.";
    };
  };

  config = mkIf (config.source.dirs != { }) {
    build.unpackScript = unpackScript;
  };
}
