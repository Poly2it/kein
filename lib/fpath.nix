{ lib, ... }: let
  splitPathString = string:
    string
    |> lib.splitString "/"
    |> lib.filter (x: x != "")
    |> lib.filter (x: x != ".");
  resolveComponents = components:
    components
    |> lib.lists.foldl (a: b:
      if b == "." then
        a
      else
        a ++ [b]) []
    |> lib.lists.foldl (a: b:
      if b == ".." then
        (lib.dropEnd 1 a)
      else
        a ++ [b]) [];
in rec {
  mkFpath = path: {
    _type = "fpath";
    root = path;
    operations = [];
    __toString = self: self |> toPath;
    __functor = self: v: enter v self;
  };
  enter = dirName: fpath: fpath // {
    operations = fpath.operations ++ (dirName |> splitPathString);
  };
  leave = fpath: fpath // {
    operations = fpath.operations ++ [".."];
  };
  components = fpath: (fpath.root |> splitPathString) ++ fpath.operations |> resolveComponents;
  fileName = fpath: fpath |> toPath |> toString |> splitPathString |> lib.lists.last;
  fileNameStem = fpath: fpath |> fileName |> lib.splitString "." |> (x: lib.elemAt x 0);
  fileExtension = fpath: fpath |> fileName |> lib.splitString "." |> lib.drop 1 |> lib.concatStringsSep ".";
  pathStem = fpath: fpath |> toPath |> splitPathString |> lib.lists.dropEnd 1;
  relativeTo = aUnresolved: bUnresolved: let
    commonPrefix = (lib.lists.commonPrefix (aUnresolved |> components) (bUnresolved |> components));
    a = aUnresolved |> components |> lib.lists.removePrefix commonPrefix;
    b = bUnresolved |> components |> lib.lists.removePrefix commonPrefix;
  in
    ((lib.forEach a (x: "..")) ++ (b |> components)) |> lib.concatStringsSep "/";
  length = fpath:
    fpath
    |> components
    |> lib.lists.length;
  deepest = fpaths:
    fpaths
    |> map (fpath:
      fpath
      |> components
      |> lib.lists.length
      |> (x: { name = fpath; length = x; })
    )
    |> lib.foldr (a: b:
      if isNull b then a else
      if a.length < b.length then a else b
    ) null
    |> (x: x.name);
  shallowest = fpaths:
    fpaths
    |> map (fpath:
      fpath
      |> components
      |> lib.lists.length
      |> (x: { name = fpath; length = x; })
    )
    |> lib.foldr (a: b:
      if isNull b then a else
      if a.length > b.length then a else b
    ) null
    |> (x: x.name);
  toPath = fpath: (lib.foldl (a: b: a + "/${b}") fpath.root fpath.operations);
}

