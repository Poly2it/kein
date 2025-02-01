{ lib, ... }: let
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
in {
  include                = package: c: c |> updateConstraint "include" (prev: prev ++ [package]) [];
  link                   = package: c: c |> updateConstraint "link" (prev: prev ++ [package]) [];
  setPositionIndependent = value: c: c |> setConstraint "positionIndependent" value;
  __functor              = value: c: c |> setConstraint "backend" "gcc";
}

