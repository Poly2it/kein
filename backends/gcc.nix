{ lib, pkgs, ... }:

rec {
  fpathToUnitConstraints = fpath: {
    backend = "gcc";
    stage = "compile";

    unit = fpath;
  };
  constraintsFromConstraintExprList = list: let
    inheritedContraints = list |> lib.mergeAttrsList;
    toolchain = constraintsToToolchain pkgs inheritedContraints;
  in inheritedContraints // {
    backend = "gcc";
    stage = "link";

    inherit toolchain;
    units = map (x: x |> compileUnit toolchain) list;
  };
  constraintsToToolchain = pkgs: constraints: {
    cc = "${pkgs.gcc}/bin/gcc";
    ld = "${pkgs.gcc}/bin/gcc";
  };
  toExecutable = name: constraintsExpr:
    if constraintsExpr.stage == "compile" then
      toExecutable name (constraintsFromConstraintExprList [constraintsExpr])
    else
      linkUnits constraintsExpr.toolchain name constraintsExpr;
  compileUnit = toolchain: unitConstraints @ { unit, ... }: lib.builders.keinDerivation {
    name = "${unit |> lib.fpath.fileNameStem}.o";
    command = let
      compileCommand = "${toolchain.cc} -c ${unit |> lib.fpath.fileName} -std=c23 -fPIC -o $out";
      includes = lib.header.parse unit |> map (x: unit |> lib.fpath.leave |> lib.fpath.enter x);
      # The last component is the file itself, which is subtracted.
      maxIncludeDepth = (includes |> lib.fpath.deepest |> lib.fpath.length) - 1;
      copyHeaders = lib.forEach includes (include:
        include
        |> lib.fpath.components
        |> lib.drop maxIncludeDepth
        |> lib.dropEnd 1
        |> lib.concatStringsSep "/"
        |> (x: "mkdir -p ${if x == "" then "." else x} && cp ${include} \"$_\"/${include |> lib.fpath.fileName}")
      ) |> lib.concatStringsSep "\n";
      unitPath =
        (
          unit
          |> lib.fpath.components
          |> lib.drop maxIncludeDepth
          |> lib.dropEnd 1
        )
        |> lib.concatStringsSep "/"
        |> (x: if x == "" then "." else x);
    in ''
      ${copyHeaders}
      mkdir -p ${unitPath}
      cd ${unitPath}
      cp ${unit} ${unit |> lib.fpath.fileName}
      echo ${compileCommand}
      ${compileCommand}
    '';
    kein = {
      inherit unitConstraints;
    };
  };
  linkUnits = toolchain: name: linkConstraints @ { units, ... }: lib.builders.keinDerivation {
    inherit name;
    command = let
      compileCommand = "${toolchain.ld} -fuse-ld=mold -o $bin/bin/${name} ${units |> lib.concatStringsSep " "}";
    in ''
      mkdir $bin/bin -p
      echo ${compileCommand}
      ${compileCommand}
    '';
    pathEntries = [pkgs.mold];
    outputs = ["bin"];
    kein = {
      inherit linkConstraints;
    };
  };
}

