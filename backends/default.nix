{ lib, pkgs, ... }:

{
  gcc = import ./gcc.nix { inherit lib pkgs; };
}

