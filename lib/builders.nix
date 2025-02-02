{ lib, pkgs, system, ... }:

{
  keinDerivation = keinexpr @ { name, command, pathEntries ? [], outputs ? ["out"], meta ? {}, kein }: derivation {
    inherit name system outputs pathEntries;
    builder = pkgs.bash |> lib.getExe;
    args = [
      "-c"
      ([
        "set -e\nexport PATH=PATH:${lib.makeBinPath ([pkgs.busybox] ++ pathEntries)}"
        command
      ] |> lib.concatStringsSep "\n")
    ];
    passthru.kein = kein;
    passthru.outPath = null;
    meta = meta // { outPath = null; };
    preferLocalBuild = true;
    allowSubstitutes = false;
  };
}

