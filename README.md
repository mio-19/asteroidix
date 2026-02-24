# asteroidix

`asteroidix` is a Robotnix-style Nix module system for building AsteroidOS images.

## What this does

- Pins AsteroidOS layers (`oe-core`, `bitbake`, `meta-asteroid`, etc.) through Nix fetchers.
- Evaluates configuration through `lib.evalModules`.
- Runs `oe-init-build-env` and `bitbake asteroid-image` in an FHS environment.
- Exposes build outputs as `config.build.image`, `config.build.img`, and `config.build.imagesDir`.
- Uses offline-by-default BitBake policy (`BB_NO_NETWORK = "1"` in default `local.conf`).

## Quick start

Build the default `dory` image directly from GitHub:

```bash
nix build github:mio-19/asteroidix#img
```

Build a specific machine in one command:

```bash
nix build github:mio-19/asteroidix#hoki-img
```

Available machine outputs are generated from [`configs.nix`](./configs.nix).

Use as a library (similar to `robotnix.lib.robotnixSystem`) in your own flake:

```nix
{
  inputs.asteroidix.url = "github:mio-19/asteroidix";

  outputs = { self, asteroidix, ... }: {
    asteroidixConfigurations.myWatch = asteroidix.lib.asteroidixSystem {
      system = "x86_64-linux";
      configuration = {
        machine = "dory";
      };
    };

    packages.x86_64-linux.default = self.asteroidixConfigurations.myWatch.img;
  };
}
```

Then build with:

```bash
nix build .#asteroidixConfigurations.myWatch.img
```

Or bootstrap that flake from the built-in template:

```bash
nix flake init -t github:mio-19/asteroidix
```

## Offline two-phase build

BitBake fetches must be done in a fixed-output derivation; normal build derivations run offline.

Self-test for `hoki` (copy/paste):

```bash
LOG="$(mktemp)"
nix build --print-build-logs --show-trace --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  system = builtins.currentSystem;
  cfg = flake.lib.asteroidixSystem {
    inherit system;
    configuration = {
      machine = "hoki";
      prefetch.enable = true;
      prefetch.hash = (import flake.inputs.nixpkgs { inherit system; }).lib.fakeHash;
    };
  };
in cfg.prefetchedSources' 2>&1 | tee "$LOG" || true

HASH="$(sed -n 's/.*got:[[:space:]]*//p' "$LOG" | tail -n1)"
echo "Detected prefetch hash: $HASH"

nix build --print-build-logs --show-trace --impure --expr "
let
  flake = builtins.getFlake (toString ./.);
  system = builtins.currentSystem;
  cfg = flake.lib.asteroidixSystem {
    inherit system;
    configuration = {
      machine = \"hoki\";
      prefetch.enable = true;
      prefetch.hash = \"${HASH}\";
    };
  };
in cfg.img"
```

Phase 1: prefetch all recipe sources (network allowed because fixed-output):

```bash
nix build --impure --expr '
let
  flake = builtins.getFlake "path:.";
  system = builtins.currentSystem;
  cfg = flake.lib.asteroidixSystem {
    inherit system;
    configuration = {
      machine = "hoki";
      prefetch.enable = true;
      prefetch.hash = (import flake.inputs.nixpkgs { inherit system; }).lib.fakeHash;
    };
  };
in cfg.prefetchedSources'
```

Use the hash from the mismatch error as `prefetch.hash`.

Phase 2: build image offline using the prefetched mirror:

```bash
nix build --impure --expr '
let
  flake = builtins.getFlake "path:.";
  system = builtins.currentSystem;
  cfg = flake.lib.asteroidixSystem {
    inherit system;
    configuration = {
      machine = "hoki";
      prefetch.enable = true;
      prefetch.hash = "sha256-REPLACE_WITH_REAL_HASH";
    };
  };
in cfg.img'
```

## Source directories

`asteroidix` provides a Robotnix-like `source.dirs.*` interface.

Add an extra source directory:

```nix
{
  source.dirs."foo/bar".src = pkgs.fetchgit {
    url = "https://example.com/repo/foobar.git";
    rev = "f506faf86b8f01f9c09aae877e00ad0a2b4bc511";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
```

Patch an existing directory:

```nix
{
  source.dirs."meta-asteroid".patches = [ ./example.patch ];
  source.dirs."meta-asteroid".postPatch = ''
    sed -i 's/hello/there/' example.txt
  '';
}
```

Supported per-directory knobs include:
- `source.dirs.<name>.enable`
- `source.dirs.<name>.relpath`
- `source.dirs.<name>.src`
- `source.dirs.<name>.patches`
- `source.dirs.<name>.postPatch`
- `source.dirs.<name>.nativeBuildInputs`
- `source.dirs.<name>.copyfiles`
- `source.dirs.<name>.linkfiles`
