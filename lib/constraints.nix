{ lib, backends, ... }:

rec {
  inferConstraintsFromFpath = fpath: let
    inherit (backends) gcc;
  in {
    "c" = gcc.fpathToUnitConstraints fpath;
    "C" = gcc.fpathToUnitConstraints fpath;
    "cc" = gcc.fpathToUnitConstraints fpath;
    "cpp" = gcc.fpathToUnitConstraints fpath;
    "cxx" = gcc.fpathToUnitConstraints fpath;
    "c++" = gcc.fpathToUnitConstraints fpath;
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
  toLibrary = name: constraintsExpr: {
    "gcc" = let
      gcc = backends.gcc;
    in if lib.hasSuffix ".so" name then
      gcc.toSharedObject name constraintsExpr
    else
      gcc.toStaticLibrary name constraintsExpr;
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
    else throw "resolveConstraint was given a value which cannot be resolved into a constraint";
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

