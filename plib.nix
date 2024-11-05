{ pkgs, lib, ... }:

rec {
  pop = n: list: lib.lists.take ((lib.lists.length list) - n) list;
  toPath = path: /. + "/${path}";
  toRelativePath = root: path: root + "/${path}";
  parentPath = path: path
    |> toString
    |> lib.splitString "/"
    |> pop 1
    |> lib.concatStringsSep "/"
    |> toPath;
  parentName = path: path
    |> lib.splitString "/"
    |> pop 1
    |> lib.concatStringsSep "/";
  resolveName = path: path
    |> lib.strings.normalizePath
    |> lib.splitString "/"
    |> lib.lists.foldl (a: b:
      if b == "." then
        a
      else
        a ++ [b]) []
    |> lib.lists.foldl (a: b:
      if b == ".." then
        (pop 1 a)
      else
        a ++ [b]) []
    |> lib.concatStringsSep "/";
  dropStorePrefix = path: path
    |> builtins.seq (
      lib.assertMsg
      (lib.path.hasStorePathPrefix path)
      "dropStorePrefix must only be supplied with strings which have a store prefix"
    )
    |> toString
    |> lib.splitString "/"
    |> lib.lists.drop 4
    |> lib.concatStringsSep "/";
  resolvePath = path: path
    |> toString
    |> lib.strings.normalizePath
    |> lib.splitString "/"
    |> lib.lists.foldl (a: b:
      if b == "." then
        a
      else
        a ++ [b]) []
    |> lib.lists.foldl (a: b:
      if b == ".." then
        (pop 1 a)
      else
        a ++ [b]) []
    |> lib.concatStringsSep "/"
    |> toPath;
  removePrefixPath = path: prefix: path
    |> toString
    |> lib.removePrefix (prefix |> toString)
    |> lib.toPath;
  splitShellArgs = x: x
    # This does not handle all types of whitespace as I have not investigated
    # which Nix support and which are broken.
    |> lib.split ''((("([^\\"]|\\.)*")|('([^\\']|\\.)*')|([^ '"]+))+)''
    |> lib.lists.filter (x: lib.isList x)
    |> map (x: lib.lists.head x)
    |> lib.lists.flatten
    |> lib.lists.filter (x: !isNull x);
  tenary = c: t: f: (if c then t else f);
  makeShellBuilder = { name, system, commands, outputs }: builtins.derivation {
    inherit name system outputs;
    builder = "${pkgs.bash}/bin/bash";
    args = [
      "-c"
      (lib.concatStringsSep "\n" [
        ''export PATH="$PATH:${pkgs.busybox}/bin"''
        (
          outputs
          |>
          map (a: "mkdir \"\$${lib.strings.escapeShellArg a}\"")
          |> lib.concatStringsSep "\n"
        )
        commands
      ])
    ];
  };
}

