{ lib, plib, ... }:

{
  c = import ./c { inherit lib plib; };
  lua = import ./lua { inherit lib plib; };
}

