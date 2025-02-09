{ lib, pkgs, ... }:

{
  gcc = import ./gcc { inherit lib pkgs; };
}

