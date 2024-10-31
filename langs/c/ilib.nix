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
      |> lib.removePrefix "#include "
      |> lib.trim
    )
    |> lib.filter (a: lib.hasPrefix "\"" a)
    |> map (x: x
      |> lib.removePrefix "\""
      |> lib.removeSuffix "\""
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

