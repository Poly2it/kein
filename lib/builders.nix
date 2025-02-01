{ lib, pkgs, system, ... }:

{
  keinDerivation = { name, command, pathEntries ? [], outputs ? ["out"], kein }: derivation {
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
    preferLocalBuild = true;
    allowSubstitutes = false;
  };
}

