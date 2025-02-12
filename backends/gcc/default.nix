{ lib, pkgs, ... }: let
  graph = (import ./graph.nix { inherit pkgs lib; });
in rec {
  fpathToUnitConstraints = fpath: let
    language = {
      "c" = "c";
      "C" = "cpp";
      "cc" = "cpp";
      "cpp" = "cpp";
      "cxx" = "cpp";
      "c++" = "cpp";
    }.${fpath |> lib.fpath.fileExtension};
  in {
    __type = "constraints";
    backend = "gcc";
    stage = "compile";
    inherit language;

    unit = fpath;
  };
  constraintsFromConstraintExprList = unresolvedList: let
    units = map (x: lib.constraints.resolveConstraint x) unresolvedList;
    childConstraints =
      ({ link ? [], include ? [], localLib ? {}, ... }: { inherit link include localLib; })
      (units |> lib.mergeAttrsList);
    language = lib.foldl (a: b: {
      "c" = b.language;
      "cpp" = "cpp";
    }.${a.language}) (lib.elemAt units 0) units;
  in {
    __type = "constraints";
    backend = "gcc";
    stage = "link";

    inherit (childConstraints) link include localLib;
    inherit units language;
  };
  horizontalConstraints = units: let
    mergedConstraints = (
      lib.foldr
      (a: b: lib.mergeAttrs a b)
      {}
      units
    );
  in
    ({ localLib ? {}, ... }: { inherit localLib; })
    mergedConstraints;
  verticalConstraints = units: let
    mergedConstraints = (
      lib.foldr
      (a: b: lib.mergeAttrsConcatenateValues a b)
      {}
      units
    );
  in
    ({ link ? [], include ? [], localLib ? {}, ... }: { inherit link include localLib; })
    mergedConstraints;
  propagateConstraintsToUnit = constraints: unit:
    unit
    |> lib.recursiveUpdate constraints
    |> (x: lib.removeAttrs x ["units"]);
  resolveLinkConstraints = constraints @ { units ? [], ... }: let
    outwardPropagatedConstraints = (verticalConstraints units);
  in (
    lib.removeAttrs
    (constraints // {
      link = constraints.link ++ outwardPropagatedConstraints.link;
      include = constraints.include ++ outwardPropagatedConstraints.include;
      localLib = constraints.localLib // outwardPropagatedConstraints.localLib;
      units = (
        lib.forEach
        units
        (unit: propagateConstraintsToUnit constraints unit)
      );
    })
    ["unit"]
  );
  toExecutable = name: unresolvedConstraints: let
    constraints = resolveLinkConstraints unresolvedConstraints;
    node = graph.mkCExecutableLinkNode constraints name;
  in
    if constraints.stage == "compile" then
      toExecutable name (constraintsFromConstraintExprList [unresolvedConstraints])
    else
      node.derivation;
  toSharedObject = name: unresolvedConstraints: let
    constraints = resolveLinkConstraints unresolvedConstraints;
    node = graph.mkCSharedObjectLinkNode constraints name;
  in
    if constraints.stage == "compile" then
      toSharedObject name (constraintsFromConstraintExprList [constraints])
    else
      node.derivation;
}

