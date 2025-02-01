{
  description = "Kein";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    kein.url = "git+file://../../..";
    kein.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { kein, ... }: kein.flakeFromKeinexpr {
    bin = { gcc, ... }: rec {
      main = ./main.c |> gcc.debug;
      default = main;
    };
  };
}

