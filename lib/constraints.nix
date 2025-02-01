{ lib, backends, ... }:

rec {
  inferConstraintsFromFpath = fpath: {
    "c" = let
      gcc = backends.gcc;
    in gcc.fpathToUnitConstraints fpath;
  }.${lib.fpath.fileExtension fpath};
  inferConstraintsFromConstraintExprList = list: let
    backend = lib.foldr list (aUnresolved: backend: let
      a = resolveConstraint aUnresolved;
    in
      if isNull backend then a.backend else
      if a.backend == "gcc" then "gcc" else
      backend
    ) null;
  in {
    "gcc" = let
      gcc = backends.gcc;
    in gcc.constraintsFromConstraintsExprList list;
  }.${backend};
  toExecutable = name: constraintsExpr: {
    "gcc" = let
      gcc = backends.gcc;
    in gcc.toExecutable name constraintsExpr;
  }.${constraintsExpr.backend};
  resolveConstraint = value:
    if lib.isPath value then let
      fpath = value |> lib.fpath.mkFpath;
    in
      inferConstraintsFromFpath fpath
    else if lib.isList value then
      value
      |> map (x: resolveConstraint)
      inferConstraintsFromConstraintExprList
    else if lib.isAttrs value then
      value
    else throw "";
}

