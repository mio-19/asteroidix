{ lib }:

let
  supportedMachines = [
    "anthias"
    "bass"
    "beluga"
    "catfish"
    "dory"
    "emulator"
    "firefish"
    "harmony"
    "hoki"
    "inharmony"
    "koi"
    "lenok"
    "minnow"
    "mooneye"
    "narwhal"
    "nemo"
    "pike"
    "ray"
    "rinato"
    "rubyfish"
    "sawfish"
    "skipjack"
    "smelt"
    "sparrow"
    "sparrow-mainline"
    "sprat"
    "sturgeon"
    "swift"
    "tetra"
    "triggerfish"
    "wren"
  ];
in
lib.genAttrs supportedMachines (machine: {
  inherit machine;
})
