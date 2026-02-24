{
  description = "A basic asteroidix configuration";

  inputs.asteroidix.url = "github:mio-19/asteroidix";

  outputs =
    { self, asteroidix }:
    {
      asteroidixConfigurations.myWatch = asteroidix.lib.asteroidixSystem {
        system = "x86_64-linux";
        configuration = import ./default.nix;
      };

      packages.x86_64-linux.default = self.asteroidixConfigurations.myWatch.img;
    };
}
