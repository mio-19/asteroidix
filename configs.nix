{ lib }:

let
  nightlyMachines = [
    "anthias"
    "aurora"
    "bass"
    "beluga"
    "catfish"
    "dory"
    "emulator"
    "eos"
    "firefish"
    "harmony"
    "hoki"
    "inharmony"
    "koi"
    "lenok"
    "medaka"
    "minnow"
    "mooneye"
    "narwhal"
    "nemo"
    "pike"
    "ray"
    "rinato"
    "rubyfish"
    "sawfish"
    "seluna"
    "skipjack"
    "smelt"
    "solios"
    "sparrow"
    "sparrow-mainline"
    "sprat"
    "sturgeon"
    "swift"
    "tetra"
    "triggerfish"
    "wren"
  ];

  # AsteroidOS 2.1 prepare-build.sh (git branch 2.0). aurora, eos, seluna, solios, and medaka arrived on nightly.
  stableMachines = lib.subtractLists [
    "aurora"
    "eos"
    "seluna"
    "solios"
    "medaka"
  ] nightlyMachines;
in
{
  machines = {
    nightly = nightlyMachines;
    stable = stableMachines;
  };

  configurations =
    lib.mapAttrs
      (
        _: machines:
        lib.genAttrs machines (machine: {
          inherit machine;
        })
      )
      {
        nightly = nightlyMachines;
        stable = stableMachines;
      };
}
