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
  setConstraints = newConstraints: unresolvedConstraints: let
    constraints = (lib.constraints.resolveConstraint unresolvedConstraints);
  in
    lib.mergeAttrs constraints newConstraints;
in {
  include                    = package: c: c |> updateConstraint "include" (prev: prev ++ [package]) [];
  link                       = package: c: c |> updateConstraint "link" (prev: prev ++ [package]) [];
  define                     = key: value: c: c |> updateConstraint "define" (prev: prev // { ${key} = value; }) {};
  setPositionIndependent     = value: c: c |> setConstraint "positionIndependent" value;
  setOptimizeLevel           = value: c: c |> setConstraint "optimizeLevel" value;
  setDebugSymbols            = value: c: c |> setConstraint "debugSymbols" value;
  sanitizeAddresses          = value: c: c |> setConstraint "sanitizeAddresses" value;
  sanitizePointerComparisons = value: c: c |> setConstraint "sanitizePointerComparisons" value;
  setStandard                = value: c: c |> setConstraint "standard" value;
  debug                      = c: c |> setConstraints {
    sanitizeAddresses = true;
    sanitizePointerComparisons = true;
    optimizeLevel = "1";
    debugSymbols = true;
    omitFramePointer = false;
  };
  __functor                  = value: c: c |> setConstraint "backend" "gcc";
}

