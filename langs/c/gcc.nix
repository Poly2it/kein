{ pkgs, lib, plib, ilib, ... }:

rec {
  ccDefaultOptions = {
    features = {
      lto = true;
    };
    optimizations = {
      level = 3;
    };
    machine = {
    };
    standard = "c99";
  };
  makeToolchain = projectRoot: options @ { localPkgs ? pkgs, ... }: lib.attrsets.recursiveUpdate rec {
    cc = "${localPkgs.gcc}/bin/gcc";
    ccOptions = ccDefaultOptions;
    ld = cc;
    ldOptions = ccOptions;
    system = localPkgs.system;
    target = localPkgs.system;
    inherit projectRoot makeCompileCommand makeLinkCommand;
  } options;
  makeCompileCommand = toolchain: { includes ? [], ... }: path: let
    ccOptions = lib.attrsets.recursiveUpdate ccDefaultOptions toolchain.ccOptions;
    in lib.concatStringsSep " " [
      toolchain.cc
      "-c"
      (plib.tenary (includes == []) "" "-I${lib.makeIncludePath includes}")
      (plib.tenary ccOptions.features.lto "-flto" "")
      (plib.tenary (ccOptions.optimizations.level == null) "" "-O${toString ccOptions.optimizations.level}")
      "-std=${ccOptions.standard |> lib.strings.escapeShellArg}"
      (path |> plib.dropStorePrefix)
      "-o" "$out/${lib.strings.escapeShellArg (ilib.makeObjectName path)}"
    ];
  makeLinkCommand = toolchain: { links ? [] }: translationUnits: name: let
    includes = translationUnits |> map (x: x.includes) |> lib.lists.flatten;
    ccOptions = lib.attrsets.recursiveUpdate ccDefaultOptions toolchain.ccOptions;
    in lib.concatStringsSep " " [
      toolchain.ld
      (translationUnits
        |> map (x: "${x.derivation}/${x.name}"
          |> lib.strings.escapeShellArg
        )
        |> lib.concatStringsSep " "
      )
      "-o" "$bin/bin/${lib.strings.escapeShellArg name}"
      (plib.tenary (includes == []) "" "-L${lib.makeLibraryPath includes}")
      (plib.tenary ccOptions.features.lto "-flto" "")
      (links |> map (x: "-l${lib.strings.escapeShellArg x}") |> lib.concatStringsSep " ")
    ];
}

