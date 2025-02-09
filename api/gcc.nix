{ lib, ... }: let

  inherit (lib.constraints) updateConstraint setConstraint setConstraints;
in {
  include                    = package: c: c |> updateConstraint "include" (prev: prev ++ (if lib.isList package then package else [package])) [];
  link                       = package: c: c |> updateConstraint "link" (prev: prev ++ (if lib.isList package then package else [package])) [];
  define                     = key: value: c: c |> updateConstraint "define" (prev: prev // { ${key} = value; }) {};
  setPositionIndependent     = value: c: c |> setConstraint "positionIndependent" value;
  setOptimizeLevel           = value: c: c |> setConstraint "optimizationLevel" value;
  enableDebugging            = value: c: c |> setConstraint "debuggingTarget" "dwarf";
  setDebuggingTarget         = value: c: c |> setConstraint "debuggingTarget" value;
  setDebuggingLevel          = value: c: c |> setConstraint "debuggingLevel" value;
  sanitizeAddresses          = value: c: c |> setConstraint "sanitizeAddresses" value;
  sanitizeKernelAddresses    = value: c: c |> setConstraint "sanitizeKernelAddresses" value;
  sanitizeThreads            = value: c: c |> setConstraint "sanitizeThreads" value;
  sanitizeUndefinedBehaviour = value: c: c |> setConstraint "sanitizeUndefinedBehaviour" value;
  sanitizeLeaks              = value: c: c |> setConstraint "sanitizeLeaks" value;
  sanitizePointerComparisons = value: c: c |> setConstraint "sanitizePointerComparisons" value;
  sanitizePointerSubtraction = value: c: c |> setConstraint "sanitizePointerSubtraction" value;
  setStandard                = value: c: c |> setConstraint "standard" value;
  setMeta                    = value: c: c |> setConstraint "meta" value;
  setArguments               = value: c: c |> setConstraints {
    arguments = value;
  };
  debug                      = c: c |> setConstraints {
    sanitizeAddresses = true;
    sanitizeUndefinedBehaviour = true;
    sanitizePointerComparisons = true;
    sanitizePointerSubtraction = true;
    optimizationLevel = "g";
    debuggingTarget = "dwarf";
    arguments.optimizationFlags.no-omit-frame-pointer = true;
  };
  __functor                  = value: c: c |> setConstraint "backend" "gcc";
}

