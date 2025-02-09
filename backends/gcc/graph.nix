{ pkgs, lib }: let
  arguments = (import ./arguments { inherit pkgs lib; });
  commands = (import ./commands.nix { inherit pkgs lib; });
  resolveLinks = { localLib ? {}, ... }: links: let
    resolvedAndUnresolvedLinks =
      links
      |> map (name:
        if lib.hasAttr name localLib then
          lib.getAttr name localLib
        else
          name
      );
  in {
    linkedDerivations = resolvedAndUnresolvedLinks |> lib.filter (x: lib.isDerivation x);
    unresolvedLinks = resolvedAndUnresolvedLinks |> lib.filter (x: lib.isString x);
  };
in rec {
  toStoreObjectReferences = units: (
    units
    |> map (x:
      if lib.isDerivation x then
        x
      else if lib.isPath x then
        x
      else if lib.isAttrs x && x.__type == "fpath" then
        x |> lib.fpath.toPath
      else if lib.isAttrs x && x.__type == "graphNode" then
        x.derivation
      else if lib.isAttrs x && x.__type == "constraints" then let
        derivation = (mkCCompileNode x).derivation;
      in
        if lib.elem "lib" derivation.outputs then
          "${derivation |> lib.getLib}/lib/${derivation.name}"
        else
          derivation
      else
        x
    )
  );
  mkCCompileNode = constraints @ {
    unit,
    ...
  }: rec {
    __type = "graphNode";
    name = "${unit |> lib.fpath.fileNameStem}.o";
    gccArguments = commands.mkCCompileArguments constraints;
    compileCommand = arguments.toCommand gccArguments [(unit |> lib.fpath.fileName)];
    includes = lib.header.parseRecursivelyFpath unit;
    derivation = lib.builders.keinDerivation {
      inherit name;
      command = let
        inherit compileCommand includes;
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
        inherit constraints;
      };
    };
  };
  mkCExecutableLinkNode = constraints @ {
    units,
    link ? [],
    ...
  }: name: rec {
    __type = "graphNode";
    inherit name;
    gccArguments =
      commands.mkCExecutableLinkArguments
      (constraints // {
        link = resolvedLinks.unresolvedLinks;
      })
      "$out/bin/${name}";
    compileCommand =
      arguments.toCommand
      gccArguments
      (resolvedUnits ++ resolvedLinks.linkedDerivations);
    resolvedLinks = resolveLinks constraints link;
    resolvedUnits = toStoreObjectReferences units;
    derivation = lib.builders.keinDerivation {
      inherit name;
      command = ''
        mkdir -p $out/bin
        echo ${compileCommand}
        ${compileCommand}
      '';
      pathEntries = [pkgs.mold];
      kein = {
        inherit constraints;
      };
      meta = {
        mainProgram = name;
      };
    };
  };
  mkCSharedObjectLinkNode = constraints @ {
    units,
    link ? [],
    ...
  }: name: rec {
    __type = "graphNode";
    inherit name;
    gccArguments =
      commands.mkCSharedObjectLinkArguments
      (constraints // {
        link = resolvedLinks.unresolvedLinks;
      })
      "$out";
    compileCommand =
      arguments.toCommand
      gccArguments
      (resolvedUnits ++ resolvedLinks.linkedDerivations);
    resolvedLinks = resolveLinks constraints link;
    resolvedUnits = toStoreObjectReferences units;
    derivation = lib.builders.keinDerivation {
      inherit name;
      command = ''
        echo ${compileCommand}
        ${compileCommand}
      '';
      pathEntries = [pkgs.mold];
      kein = {
        inherit constraints;
      };
    };
  };
}

