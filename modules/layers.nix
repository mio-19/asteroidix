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
    rev = "62e6eb6003f2ad3a8952519e7a3dd7df700c26fc";
    hash = "sha256-klDMjwIhTuZXosqCt9F1A5nxiUBTZl6w7PBv8LEkNM0=";
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
    rev = "e197f861f1441b56baab6af4a30f68abcf041d0b";
    hash = "sha256-Hb99RYhiohXiRmnpGvaavwGB4PEguM/wbR17zw1Ir7s=";
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
    rev = "750506ad678a2b142f044fd4667655b7f1c702ea";
    hash = "sha256-7C1PMs7e6toXOUSJNZS3ygZB/Xer1GJS86ladaxEo2s=";
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
