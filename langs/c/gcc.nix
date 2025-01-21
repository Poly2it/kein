{ pkgs, lib, plib, ilib, ... }:

rec {
  ccDefaultOptions = {
    features = {
      lto = true;
      fatLtoObjects = false;
    };
    optimizations = {
      level = 3;
    };
    machine = {
      arch = "x86-64";
    };
    debugging = {
      native = false;
      gdb = false;
    };
    instrumentation = {
      generate = false;
    };
    standard = "c99";
    stdlib = true;
  };
  makeToolchain = projectRoot: options @ { localPkgs ? pkgs, ... }: lib.attrsets.recursiveUpdate rec {
    cc = "${localPkgs.gcc}/bin/gcc";
    ccOptions = ccDefaultOptions;
    ld = cc;
    ldOptions = ccOptions;
    ar = "${localPkgs.bintools}/bin/ar";
    system = localPkgs.system;
    target = localPkgs.system;
    inherit projectRoot makeCompileCommand makeLinkCommand;
  } options;
  makeCompileCommand = toolchain: { includes ? [], ... }: path: let
    ccOptions = lib.attrsets.recursiveUpdate ccDefaultOptions toolchain.ccOptions;
    in lib.concatStringsSep " " [
      toolchain.cc
      "-c"
      (plib.tenary (includes == []) "" "-I${lib.concatStringsSep " -I" includes}")
      (plib.tenary ccOptions.features.lto "-flto" "")
      (plib.tenary ccOptions.features.fatLtoObjects "-ffat-lto-objects" "")
      (plib.tenary (ccOptions.optimizations.level == null) "" "-O${toString ccOptions.optimizations.level}")
      "-std=${ccOptions.standard |> lib.strings.escapeShellArg}"
      (path |> plib.dropStorePrefix)
      (plib.tenary ccOptions.stdlib "-nostdlib" "")
      (plib.tenary ccOptions.debugging.native "-g" "")
      (plib.tenary ccOptions.debugging.gdb    "-ggdb" "")
      (plib.tenary ccOptions.instrumentation.generate    "-pg" "")
      "-march=${ccOptions.machine.arch |> lib.strings.escapeShellArg}"
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
      (plib.tenary (includes == []) "" "-L${lib.makeLibraryPath (includes |> lib.lists.unique)}")
      (plib.tenary ccOptions.features.lto "-flto" "")
      (links |> lib.lists.unique |> map (x: "-l${lib.strings.escapeShellArg x}") |> lib.concatStringsSep " ")
    ];
}

