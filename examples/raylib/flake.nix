{
  description = "Kein";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    kein.url = "git+file://../../..";
    kein.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { kein, ... }: kein.flakeFromKeinexpr {
    meta = { lib, ... }: {
      name = "rayprogram";
      license = lib.licenses.lgpl3;
    };
    licenseFile = ../../LICENSE;
    distributedFiles = [
      ./NOTES.txt
    ];
    bin = { pkgs, gcc, ... }: {
      rayprogram =
        [
          ./main.c
          ./utils.c
        ]
        |> gcc.include pkgs.raylib
        |> gcc.link "raylib"
        |> gcc.setPositionIndependent true;
    };
  };
}

