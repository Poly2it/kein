{ pkgs, lib, plib, ... }:

{
  c = import ./c { inherit pkgs lib plib; };
  lua = import ./lua { inherit pkgs lib plib; };
}

