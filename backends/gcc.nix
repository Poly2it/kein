{ lib, pkgs, ... }:

rec {
  fpathToUnitConstraints = fpath: {
    backend = "gcc";
    stage = "compile";

    unit = fpath;
  };
  constraintsFromConstraintExprList = unresolvedList: let
    units = map (x: lib.constraints.resolveConstraint x) unresolvedList;
    inheritedContraints = units |> lib.mergeAttrsList;
  in inheritedContraints // {
    backend = "gcc";
    stage = "link";

    inherit units;
  };
  constraintsToToolchain = pkgs: constraints: {
    cc = "${pkgs.gcc}/bin/gcc";
    ld = "${pkgs.gcc}/bin/gcc";
  };
  propagateConstraintsFromUnits = constraints @ {
    positionIndependent ? false,
    ...
  }: units: (
    lib.foldr
    (a: b: lib.mergeAttrs a b)
    constraints
    units) // {
      positionIndependentExecutable = positionIndependent;
    };
  propagateConstraintsToUnit = constraints @ {
    positionIndependent ? false,
    ...
  }: unit:
    unit
    |> lib.mergeAttrs constraints
    |> (x: lib.removeAttrs x ["units"])
    |> (constraints: constraints // {
      positionIndependentExecutable = positionIndependent;
    });
  toExecutable = name: unresolvedConstraints @ { units ? [], ... }: let
    mergedConstraints = propagateConstraintsFromUnits unresolvedConstraints units;
    constraints = lib.removeAttrs (lib.mergeAttrs mergedConstraints {
      units = lib.forEach unresolvedConstraints.units (unit: propagateConstraintsToUnit mergedConstraints unit);
    }) ["unit"];
  in
    if constraints.stage == "compile" then
      toExecutable name (constraintsFromConstraintExprList [unresolvedConstraints])
    else
      linkUnits (constraintsToToolchain pkgs constraints) name constraints;
  generateCommand = listOptsPre: keyOpts: listOptsPost: [
    (listOptsPre |> lib.flatten)
    (
      keyOpts
      |> lib.mapAttrsToList (name: value:
        if builtins.isBool value then
          if value then
            "-${name}"
          else
            ""
        else if value == "" then
          ""
        else
          "-${name}=${value}"
      )
      |> lib.filter (x: x != "")
      |> lib.naturalSort
      |> lib.concatStringsSep " "
    )
    (listOptsPost |> lib.flatten)
  ] |> lib.flatten |> lib.concatStringsSep " ";
  generateCompileCommand = toolchain: {
    unit,
    include ? [],
    positionIndependentCode ? false,
    positionIndependentExecutable ? false,
    standard ? "c23",
    ...
  }: generateCommand [
    toolchain.cc
    "-c"
    (unit |> lib.fpath.fileName)
  ] {
    std = standard;
    fPIC = positionIndependentCode;
    fPIE = positionIndependentExecutable;
  } [
    "-o"
    "$out"
    (lib.forEach include (x: "-I${lib.makeIncludePath [x]}"))
  ];
  generateLinkCommand = toolchain: name: {
    units,
    include ? [],
    link ? [],
    positionIndependentCode ? false,
    positionIndependentExecutable ? false,
    ...
  }: generateCommand [
    toolchain.ld
    "-o"
    "$bin/bin/${name}"
  ] {
    fuse-ld = "mold";
    fPIC = positionIndependentCode;
    fPIE = positionIndependentExecutable;
    "Wl,-rpath" = lib.makeLibraryPath include;
  } [
    (lib.forEach units (x: compileUnit (constraintsToToolchain pkgs units) x))
    (lib.forEach include (x: "-L${lib.makeLibraryPath [x]}"))
    (lib.forEach link (x: "-l${x}"))
  ];
  compileUnit = toolchain: unitConstraints @ { unit, ... }: lib.builders.keinDerivation {
    name = "${unit |> lib.fpath.fileNameStem}.o";
    command = let
      compileCommand = generateCompileCommand toolchain unitConstraints;
      includes = lib.header.parse unit |> map (x: unit |> lib.fpath.leave |> lib.fpath.enter x);
      # The last component is the file itself, which is subtracted.
      maxIncludeDepth = if lib.length includes > 0 then (includes |> lib.fpath.deepest |> lib.fpath.length) - 1 else 0;
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
  linkUnits = toolchain: name: linkConstraints: lib.builders.keinDerivation {
    inherit name;
    command = let
      compileCommand = generateLinkCommand toolchain name linkConstraints;
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

