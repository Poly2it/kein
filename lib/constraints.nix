{ lib, backends, ... }:

rec {
  inferConstraintsFromFpath = fpath: {
    "c" = let
      gcc = backends.gcc;
    in gcc.fpathToUnitConstraints fpath;
  }.${lib.fpath.fileExtension fpath};
  inferConstraintsFromConstraintExprList = list: let
    backend = lib.foldr (aUnresolved: backend: let
      a = resolveConstraint aUnresolved;
    in
      if isNull backend then a.backend else
      if a.backend == "gcc" then "gcc" else
      throw "Cannot infer constraints from list of constraints"
    ) null list;
  in {
    "gcc" = let
      gcc = backends.gcc;
    in gcc.constraintsFromConstraintExprList list;
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
      |> inferConstraintsFromConstraintExprList
    else if lib.isAttrs value then
      value
    else throw value;
}

