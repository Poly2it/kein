{ lib, plib, ilib, ... }:

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
  };
  makeToolchain = pkgs: projectRoot: rec {
    cc = "${pkgs.gcc}/bin/gcc";
    ccOptions = ccDefaultOptions;
    ld = cc;
    ldOptions = ccOptions;
    system = pkgs.system;
    target = pkgs.system;
    inherit projectRoot makeCompileCommand makeLinkCommand;
  };
  makeCompileCommand = toolchain: { includes ? [] }: path: let
    ccOptions = lib.attrsets.recursiveUpdate ccDefaultOptions toolchain.ccOptions;
    in lib.concatStringsSep " " [
      toolchain.cc
      "-c"
      (plib.tenary (includes == []) "" "-I${lib.makeIncludePath includes}")
      (plib.tenary ccOptions.features.lto "-flto" "")
      (plib.tenary (ccOptions.optimizations.level == null) "" "-O${toString ccOptions.optimizations.level}")
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

