{ lib, plib, ... }:

rec {
  makeObjectName = path: path
    |> toString
    |> lib.strings.splitString "/"
    |> lib.lists.last
    |> lib.strings.removeSuffix ".c"
    |> (a: "${a}.o");
  relativeIncludes = projectRoot: path: path
    |> lib.readFile
    |> lib.addErrorContext "Included file '${path}' could not be found"
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
      |> (a: ((plib.parentPath path) |> plib.dropStorePrefix) + "/" + a)
      |> plib.toRelativePath projectRoot
      |> plib.resolvePath
    )
    |> lib.lists.unique;
  recursiveRelativeIncludes = projectRoot: path:
    (relativeIncludes projectRoot path) ++ ((relativeIncludes projectRoot path)
      |> map (x: (recursiveRelativeIncludes projectRoot x) |> lib.addErrorContext "In '${x}', included by '${path}'")
      |> lib.lists.flatten
      |> lib.lists.unique
    );
}

