{ lib, ... }: let

  inherit (lib.constraints) updateConstraint setConstraint setConstraints;
in {
  include                    = package: c: c |> updateConstraint "include" (prev: prev ++ (if lib.isList package then package else [package])) [];
  link                       = package: c: c |> updateConstraint "link" (prev: prev ++ (if lib.isList package then package else [package])) [];
  define                     = key: value: c: c |> updateConstraint "define" (prev: prev // { ${key} = value; }) {};
  setPositionIndependent     = value: c: c |> setConstraint "positionIndependent" value;
  setOptimizeLevel           = value: c: c |> setConstraint "optimizeLevel" value;
  setDebugSymbols            = value: c: c |> setConstraint "debugSymbols" value;
  sanitizeAddresses          = value: c: c |> setConstraint "sanitizeAddresses" value;
  sanitizePointerComparisons = value: c: c |> setConstraint "sanitizePointerComparisons" value;
  setStandard                = value: c: c |> setConstraint "standard" value;
  setMeta                    = value: c: c |> setConstraint "meta" value;
  debug                      = c: c |> setConstraints {
    sanitizeAddresses = true;
    sanitizePointerComparisons = true;
    optimizeLevel = "1";
    debugSymbols = true;
    omitFramePointer = false;
  };
  __functor                  = value: c: c |> setConstraint "backend" "gcc";
}

