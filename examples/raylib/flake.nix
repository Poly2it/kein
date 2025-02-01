{
  description = "Kein";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    kein.url = "git+file://../../..";
    kein.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { kein, ... }: kein.flakeFromKeinexpr {
    bin = { pkgs, gcc, ... }: rec {
      main =
        [
          ./main.c
          ./utils.c
        ]
        |> gcc.include pkgs.raylib
        |> gcc.link "raylib"
        |> gcc.setPositionIndependent true;
      default = main;
    };
  };
}

