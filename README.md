# asteroidix

`asteroidix` is a Robotnix-style Nix module system for building AsteroidOS images.

## What this does

- Pins AsteroidOS layers (`oe-core`, `bitbake`, `meta-asteroid`, etc.) through Nix fetchers.
- Evaluates configuration through `lib.evalModules`.
- Runs `oe-init-build-env` and `bitbake asteroid-image` in an FHS environment.
- Exposes build outputs as `config.build.image`, `config.build.img`, and `config.build.imagesDir`.
- Uses offline-by-default BitBake policy (`BB_NO_NETWORK = "1"` in default `local.conf`).
- Stores per-device prefetch hashes in [`prefetch-lock.json`](./prefetch-lock.json) so users can build without re-discovering hashes.

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
When a device hash exists in [`prefetch-lock.json`](./prefetch-lock.json), prefetch mode is enabled automatically.

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

Update the prefetch lock for a specific machine:

```bash
nix run .#update-prefetch-lock -- hoki
```

## Offline two-phase build

Normal image builds run offline. Keep/update the per-device prefetch lock, then build:

```bash
nix run .#update-prefetch-lock -- hoki
nix build .#hoki-img
```

If you are working from an uncommitted tree, use `path:.`:

```bash
nix run path:.#update-prefetch-lock -- hoki
nix build path:.#hoki-img
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
