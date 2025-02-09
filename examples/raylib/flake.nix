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
    lib = { pkgs, gcc, ... }: {
      "utils.so" =
        [./utils.c]
        |> gcc.include pkgs.raylib
        |> gcc.link "raylib";
    };
    bin = { pkgs, gcc, ... }: {
      rayprogram =
        [./main.c]
        |> gcc.include pkgs.raylib
        |> gcc.link "raylib"
        |> gcc.link "utils"
        |> gcc.setPositionIndependent true;
    };
  };
}

