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
  updateConstraint = attr: f: default: unresolvedConstraints: let
    constraints = (lib.constraints.resolveConstraint unresolvedConstraints);
  in
    lib.setAttr constraints attr (f (
      if lib.hasAttr attr constraints then
        lib.getAttr attr constraints
      else default
    ));
  setConstraint = attr: value: unresolvedConstraints: let
    constraints = (lib.constraints.resolveConstraint unresolvedConstraints);
  in
    lib.setAttr constraints attr value;
  setConstraints = newConstraints: unresolvedConstraints: let
    constraints = (lib.constraints.resolveConstraint unresolvedConstraints);
  in
    lib.mergeAttrs constraints newConstraints;
  setUnsetConstraints = newConstraints: unresolvedConstraints: let
    constraints = (lib.constraints.resolveConstraint unresolvedConstraints);
  in
    lib.mergeAttrs newConstraints constraints;

}

