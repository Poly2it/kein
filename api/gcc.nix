{ lib, ... }:

{
  include = package: unresolvedConstraints: let
    constraints = lib.constraints.resolveConstraint unresolvedConstraints;
  in constraints // {
    include = (if (lib.hasAttr "include" constraints) then constraints.include else []) ++ [package];
  };
  link = name: unresolvedConstraints: let
    constraints = lib.constraints.resolveConstraint unresolvedConstraints;
  in constraints // {
    link = (if (lib.hasAttr "link" constraints) then constraints.link else []) ++ [name];
  };
  setPositionIndependent = value: unresolvedConstraints: let
    constraints = lib.constraints.resolveConstraint unresolvedConstraints;
  in constraints // {
    positionIndependent = value;
  };
  __functor = unresolvedConstraints: let
    constraints = lib.constraints.resolveConstraint unresolvedConstraints;
  in constraints // {
    backend = "gcc";
  };
}

