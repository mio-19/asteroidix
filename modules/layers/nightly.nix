{
  openembedded-core = {
    owner = "openembedded";
    repo = "openembedded-core";
    ref = "whinlatter";
    rev = "8751ec83421192fc0f8495fb95798f9eb7be77a0";
    hash = "sha256-lFEfanDr+G0S6h3FL9793L3383qIvhzw7K5kSUKmAt0=";
    relpath = "src/oe-core";
  };

  bitbake = {
    owner = "openembedded";
    repo = "bitbake";
    ref = "2.16";
    rev = "713fbbdb9ecc195ceb2216a2345e0d79dbee2135";
    hash = "sha256-mqVQBtlfLQsg2LA240N8byn+vRZ+x0MVUIM1Jw2h3gg=";
    relpath = "src/oe-core/bitbake";
  };

  meta-openembedded = {
    owner = "openembedded";
    repo = "meta-openembedded";
    ref = "whinlatter";
    rev = "f52f32952cb9717949f8bc3d3ccf6c4c5a59521f";
    hash = "sha256-Xd0hYx0kn3ifhxnyzcaPRlECHpR3uLQYzQjEKOalOf4=";
    relpath = "src/meta-openembedded";
  };

  meta-qt6 = {
    url = "https://code.qt.io/yocto/meta-qt6.git";
    ref = "6.11";
    rev = "ec98b3ab1c8deeab9412ef6cbfd55729dc567b01";
    hash = "sha256-Kf8E6Vy6ytVxLLjr5DKEeiZXLKBK4MolDdJDKFoEpFg=";
    relpath = "src/meta-qt6";
  };

  meta-smartphone = {
    owner = "shr-distribution";
    repo = "meta-smartphone";
    ref = "whinlatter";
    rev = "0ef4e8979fbf3403ff8aef977874496dc312d913";
    hash = "sha256-cGc3FzZrY+z7baJT0vUFHuul8DGaHeLqeNDLlCRECR8=";
    relpath = "src/meta-smartphone";
  };

  meta-asteroid = {
    owner = "AsteroidOS";
    repo = "meta-asteroid";
    ref = "master";
    rev = "c5b82318a9d065f37d7f4ec90e272721288797b5";
    hash = "sha256-LCNYJI/cTBnNz4iMGO1epbRzMt+9rD3ciaOmUGp03GA=";
    relpath = "src/meta-asteroid";
  };

  meta-clang = {
    owner = "kraj";
    repo = "meta-clang";
    ref = "whinlatter";
    rev = "cf20f8bd1366d41094c945597b95dd746e87b871";
    hash = "sha256-rqSTRC/m8k3sEOv3z9RCEhEEp7ku06K3ITSAPixT3To=";
    relpath = "src/meta-clang";
  };

  meta-asteroid-community = {
    owner = "AsteroidOS";
    repo = "meta-asteroid-community";
    ref = "master";
    rev = "f911d8900b2da887d1486416a8c16b8f8f15dd35";
    hash = "sha256-aSapL4RQP7r7uUZ/YUR2nQj+nvtMk9xFSWs8kKy8e9A=";
    relpath = "src/meta-asteroid-community";
  };

  meta-smartwatch = {
    owner = "AsteroidOS";
    repo = "meta-smartwatch";
    ref = "master";
    rev = "085844a91fd23691f55d8ac08bc3e4c0a8429936";
    hash = "sha256-V7XDaIUcg7noQvhS3YM9HgTnipaAqYyuw7bi0ZUFzVg=";
    relpath = "src/meta-smartwatch";
  };

  meta-virtualization = {
    url = "https://git.yoctoproject.org/meta-virtualization";
    ref = "whinlatter";
    rev = "8f03a0cc8950ef5d5e4f11d9ae494946d1991e45";
    hash = "sha256-sMTxige4I2gMnEBNVM4LS1eTBFIaa6029fbTU/4pH1k=";
    relpath = "src/meta-virtualization";
  };
}
