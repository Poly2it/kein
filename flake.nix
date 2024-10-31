{
  description = "Kein build system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
    inherit (pkgs) lib;
    plib = import ./plib.nix { inherit pkgs lib; };
  in {
    langs = import ./langs { inherit pkgs lib plib; };
  };
}

