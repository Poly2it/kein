{ lib, plib, ... }:

rec {
  makeObjectName = path: path
    |> toString
    |> lib.strings.splitString "/"
    |> lib.lists.last
    |> lib.strings.removeSuffix ".c"
    |> (a: "${a}.o");
  relativeIncludes = source:
    source
    |> lib.splitString "\n"
    |> lib.filter (a: lib.hasPrefix "#include " a)
    |> map (x: x
      |> lib.strings.split ''#include ( |(/\*.*\*/))*(".*")|(<.*>)''
      |> lib.filter (a: lib.isList a)
      |> lib.lists.flatten
      |> lib.filter (a: builtins.isString a)
      |> lib.lists.last
    )
    |> lib.filter (a: lib.hasPrefix "\"" a)
    |> map (x: x
      |> lib.strings.removePrefix "\""
      |> lib.strings.removeSuffix "\""
    )
    |> lib.lists.unique;
  recursiveResolvedIncludes = generatedSource: projectRoot: fullName:
  let
    source =
      if (lib.hasAttr fullName generatedSource) then
        lib.readFile (generatedSource.${fullName}.derivation + "/generated")
      else
        lib.readFile (plib.toRelativePath projectRoot fullName);
    parentFullName = fullName |> plib.parentName;
    sourceRelativeIncludes = relativeIncludes source;
    sourceIncludes =
      sourceRelativeIncludes
      |> map (x:
        plib.tenary (parentFullName == "") x "${parentFullName}/${x}"
        |> plib.resolveName
      )
      |> lib.filter (x: !isNull x);
  in
    sourceIncludes ++ (map
      (x: recursiveResolvedIncludes generatedSource projectRoot x) sourceIncludes
    )
    |> lib.lists.flatten;
}

