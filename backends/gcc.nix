{ lib, pkgs, ... }: let
  assertOneOf = name: val: xs: (lib.assertOneOf name val xs) |> (v: if v then val else throw "");
in rec {
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
    ar = "${pkgs.gcc}/bin/ar";
    cc = "${pkgs.gcc}/bin/gcc";
    ld = "${pkgs.gcc}/bin/gcc";
  };
  propagateConstraintsFromUnits = constraints @ {
    ...
  }: units: (
    lib.foldr
    (a: b: lib.mergeAttrs a b)
    constraints
    units);
  propagateConstraintsToUnit = constraints @ {
    ...
  }: unit:
    unit
    |> lib.mergeAttrs constraints
    |> (x: lib.removeAttrs x ["units"]);
  toExecutable = name: unresolvedConstraints @ {
    units ? [],
    positionIndependent ? false,
    positionIndependentExecutable ? positionIndependent,
    ...
  }: let
    mergedConstraints = (propagateConstraintsFromUnits unresolvedConstraints units) // {
      inherit positionIndependent positionIndependentExecutable;
    };
    constraints = lib.removeAttrs (lib.mergeAttrs mergedConstraints {
      units = lib.forEach unresolvedConstraints.units (unit: propagateConstraintsToUnit mergedConstraints unit);
    }) ["unit"];
  in
    if constraints.stage == "compile" then
      toExecutable name (constraintsFromConstraintExprList [unresolvedConstraints])
    else
      linkUnits (constraintsToToolchain pkgs constraints) name constraints;
  toStaticLibrary = name: unresolvedConstraints @ {
    units ? [],
    positionIndependent ? false,
    positionIndependentCode ? positionIndependent,
    ...
  }: let
    mergedConstraints = (propagateConstraintsFromUnits unresolvedConstraints units) // {
      inherit positionIndependent positionIndependentCode;
    };
    constraints = lib.removeAttrs (lib.mergeAttrs mergedConstraints {
      units = lib.forEach unresolvedConstraints.units (unit: propagateConstraintsToUnit mergedConstraints unit);
    }) ["unit"];
  in
    if constraints.stage == "compile" then
      toStaticLibrary name (constraintsFromConstraintExprList [unresolvedConstraints])
    else
      archiveUnits (constraintsToToolchain pkgs constraints) name constraints;
  toSharedLibrary = name: unresolvedConstraints @ {
    units ? [],
    positionIndependent ? true,
    positionIndependentCode ? positionIndependent,
    ...
  }: let
    mergedConstraints = (propagateConstraintsFromUnits unresolvedConstraints units) // {
      inherit positionIndependent positionIndependentCode;
    };
    constraints = lib.removeAttrs (lib.mergeAttrs mergedConstraints {
      units = lib.forEach unresolvedConstraints.units (unit: propagateConstraintsToUnit mergedConstraints unit);
    }) ["unit"];
  in
    if constraints.stage == "compile" then
      toSharedLibrary name (constraintsFromConstraintExprList [unresolvedConstraints])
    else
      linkSharedObject (constraintsToToolchain pkgs constraints) name constraints;
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
  generateBaseCommand = {
    positionIndependentCode ? false,
    positionIndependentExecutable ? false,
    optimizeLevel ? "2",
    debugSymbols ? false,
    sanitizeAddress ? false || sanitizePointerComparisons,
    sanitizePointerComparisons ? false,
    omitFramePointer ? true,
    standard ? "c23",
    ...
  }: listOptsPre: keyOpts: listOptsPost: (
    generateCommand
    listOptsPre
    {
      std = assertOneOf "standard" standard [
        # c90
        "c90"
        "c89"
        "iso9899:1990"
        "iso9899:199409"
        # c99
        "c99"
        "c9x"
        "iso9899:1999"
        "iso9899:199x"
        # c11
        "c11"
        "c1x"
        "iso9899:2011"
        # c17
        "c17"
        "c18"
        "iso9899:2017"
        "iso9899:2018"
        # c23
        "c23"
        "c2x"
        "iso9899:2024"
        # c2y
        "c2y"
        # GNU 89
        "gnu90"
        "gnu89"
        # GNU 99
        "gnu99"
        "gnu9x"
        # GNU 11
        "gnu11"
        "gnu1x"
        # GNU 17
        "gnu17"
        "gnu18"
        # GNU 23
        "gnu23"
        "gnu2x"
        # GNU 2Y
        "gnu2y"
        # C++ 1998
        "c++98"
        "c++03"
        # GNU++ 1998
        "gnu++98"
        "gnu++03"
        # C++ 2011
        "c++11"
        "c++0x"
        # GNU++ 2011
        "gnu++11"
        "gnu++0x"
        # C++ 2014
        "c++14"
        "c++1y"
        # GNU++ 2014
        "gnu++14"
        "gnu++1y"
        # C++ 2017
        "c++17"
        "c++1z"
        # GNU++ 2017
        "gnu++17"
        "gnu++1z"
        # C++ 2020
        "c++20"
        "c++2a"
        # GNU++ 2020
        "gnu++20"
        "gnu++2a"
        # C++ 2023
        "c++23"
        "c++2b"
        # GNU++ 2023
        "gnu++23"
        "gnu++2b"
        # C++ 202C
        "c++2c"
        "c++26"
        # GNU++ 202C
        "gnu++2c"
        "gnu++26"
      ];
      fPIC = positionIndependentCode;
      fPIE = positionIndependentExecutable;
      g = debugSymbols;
    }
    ([
      "-O${assertOneOf "optimizeLevel" optimizeLevel [
        "0"
        "1"
        "2"
        "3"
        "z"
      ]}"
      (if omitFramePointer then "-fomit-frame-pointer" else "-fno-omit-frame-pointer")
      (if sanitizeAddress then "-fsanitize=address" else "")
      (if sanitizePointerComparisons then "-fsanitize=pointer-compare" else "")
    ] ++ listOptsPost)
  );
  generateCompileCommand = toolchain: constraints @ {
    unit,
    include ? [],
    ...
  }: (
    generateBaseCommand
    constraints
    [
      toolchain.cc
      "-c"
      (unit |> lib.fpath.fileName)
    ]
    {
    }
    [
      "-o"
      "$out"
      (lib.forEach include (x: "-I${lib.makeIncludePath [x]}"))
    ]
  );
  generateLinkCommand = toolchain: name: constraints @ {
    units,
    include ? [],
    link ? [],
    nativeLib ? {},
    ...
  }: let
    resolvedAndUnresolvedLinks =
      link
      |> map (name:
        if lib.hasAttr name nativeLib then
          lib.getAttr name nativeLib
        else
          name
      );
    resolvedLinks = resolvedAndUnresolvedLinks |> lib.filter (x: lib.isDerivation x);
    unresolvedLinks = resolvedAndUnresolvedLinks |> lib.filter (x: lib.isString x);
  in (
    generateBaseCommand
    constraints
    [
      toolchain.ld
      "-o"
      "$bin/bin/${name}"
    ]
    {
      fuse-ld = "mold";
      "Wl,-rpath" = lib.makeLibraryPath include;
    }
    [
      (lib.forEach units (x: compileUnit (constraintsToToolchain pkgs units) x))
      (lib.forEach include (x: "-L${lib.makeLibraryPath [x]}"))
      (lib.forEach unresolvedLinks (x: "-l${x}"))
      resolvedLinks
    ]
  );
  generateSharedObjectLinkCommand = toolchain: name: constraints @ {
    units,
    include ? [],
    ...
  }: (
    generateBaseCommand
    constraints
    [
      toolchain.ld
      "-shared"
      (lib.forEach units (x: compileUnit (constraintsToToolchain pkgs units) x))
    ]
    {
      fuse-ld = "mold";
      "Wl,-rpath" = lib.makeLibraryPath include;
    }
    [
      "-o"
      "$out"
    ]
  );
  compileUnit = toolchain: unitConstraints @ { unit, ... }: lib.builders.keinDerivation {
    name = "${unit |> lib.fpath.fileNameStem}.o";
    command = let
      compileCommand = generateCompileCommand toolchain unitConstraints;
      includes = lib.header.parseRecursivelyFpath unit;
      # The last component is the file itself, which is subtracted.
      maxIncludeDepth = lib.min (if lib.length includes > 0 then (includes |> lib.fpath.deepest |> lib.fpath.length) - 1 else 0) ((unit |> lib.fpath.length) - 1);
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
    meta.mainProgram = name;
  };
  linkSharedObject = toolchain: name: linkConstraints: lib.builders.keinDerivation {
    inherit name;
    command = let
      compileCommand = generateSharedObjectLinkCommand toolchain name linkConstraints;
    in ''
      echo ${compileCommand}
      ${compileCommand}
    '';
    pathEntries = [pkgs.mold];
    kein = {
      inherit linkConstraints;
    };
    meta.mainProgram = name;
  };
  generateArchiveCommand = toolchain: name: { units, ... }: (
    generateCommand
    [
      toolchain.ar
      "rcs"
      "$out"
    ]
    {}
    [
      (lib.forEach units (x: compileUnit (constraintsToToolchain pkgs units) x))
    ]
  );
  archiveUnits = toolchain: name: linkConstraints: lib.builders.keinDerivation {
    inherit name;
    command = let
      compileCommand = generateArchiveCommand toolchain name linkConstraints;
    in ''
      echo ${compileCommand}
      ${compileCommand}
    '';
    pathEntries = [pkgs.mold];
    kein = {
      inherit linkConstraints;
    };
    meta.mainProgram = name;
  };
}

