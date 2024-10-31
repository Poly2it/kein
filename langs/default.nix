{ lib, plib, ... }:

{
  c = import ./c { inherit lib plib; };
}

