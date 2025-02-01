{
  description = "Kein";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }: let
    pkgsFor = system: import nixpkgs { inherit system; };
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (pkgsFor system) system);
  in {
    flakeFromKeinexpr = { bin ? {}, default ? null }: {
      overlays.default = final: prev: {
      };
      packages = forAllSystems (pkgs: system: let
        lib = pkgs.lib // {
          fpath = (import ./lib/fpath.nix { inherit lib; });
          header = (import ./lib/header.nix { inherit lib; });
        };
        pathToUnitConstraints = path: {
          unit = path |> lib.fpath.mkFpath;
        };
        listToLinkConstraints = list: let
          inheritedContraints = list |> map (x: x.passthru.kein.unitConstraints) |> lib.mergeAttrsList;
        in inheritedContraints // {
          units = list;
        };
        constraintsToToolchain = pkgs: constraints: {
          cc = "${pkgs.gcc}/bin/gcc";
          ld = "${pkgs.gcc}/bin/gcc";
        };
        keinDerivation = { name, command, pathEntries ? [], outputs ? ["out"], kein }: derivation {
          inherit name system outputs pathEntries;
          builder = pkgs.bash |> lib.getExe;
          args = [
            "-c"
            ([
              "set -e\nexport PATH=PATH:${lib.makeBinPath ([pkgs.busybox] ++ pathEntries)}"
              command
            ] |> lib.concatStringsSep "\n")
          ];
          passthru.kein = kein;
          passthru.outPath = null;
          preferLocalBuild = true;
          allowSubstitutes = false;
        };
        compileUnit = toolchain: unitConstraints @ { unit, ... }: keinDerivation {
          name = "${unit |> lib.fpath.fileNameStem}.o";
          command = let
            compileCommand = "${toolchain.cc} -c ${unit |> lib.fpath.fileName} -std=c23 -fPIC -o $out";
            includes = lib.header.parse unit |> map (x: unit |> lib.fpath.leave |> lib.fpath.enter x);
            # The last component is the file itself, which is subtracted.
            maxIncludeDepth = (includes |> lib.fpath.deepest |> lib.fpath.length) - 1;
            copyHeaders = lib.forEach includes (include:
              include
              |> lib.fpath.components
              |> lib.drop maxIncludeDepth
              |> lib.dropEnd 1
              |> lib.concatStringsSep "/"
              |> (x: "mkdir -p ${if x == "" then "." else x} && cp ${include} \"$_\"/${include |> lib.fpath.fileName}")
            ) |> lib.concatStringsSep "\n";
            unitPath =
              (
                unit
                |> lib.fpath.components
                |> lib.drop maxIncludeDepth
                |> lib.dropEnd 1
              )
              |> lib.concatStringsSep "/"
              |> (x: if x == "" then "." else x);
          in ''
            ${copyHeaders}
            mkdir -p ${unitPath}
            cd ${unitPath}
            cp ${unit} ${unit |> lib.fpath.fileName}
            echo ${compileCommand}
            ${compileCommand}
          '';
          kein = {
            inherit unitConstraints;
          };
        };
        linkUnits = toolchain: name: linkConstraints @ { units, ... }: keinDerivation {
          inherit name;
          command = let
            compileCommand = "${toolchain.ld} -fuse-ld=mold -o $bin/bin/${name} ${units |> lib.concatStringsSep " "}";
          in ''
            mkdir $bin/bin -p
            echo ${compileCommand}
            ${compileCommand}
          '';
          pathEntries = [pkgs.mold];
          outputs = ["bin"];
          kein = {
            inherit linkConstraints;
          };
        };
      in
        bin
        |> lib.attrsToList
        |> (x: x ++ [{ name = "default"; value = default; }])
        |> map ({ name, value }: (
          if lib.isPath value then let
            unitConstraints =
              value
              |> pathToUnitConstraints;
            unit =
              unitConstraints
              |> compileUnit (constraintsToToolchain pkgs unitConstraints);
          in {
            inherit name;
            value =
              unit
              |> lib.singleton
              |> listToLinkConstraints
              |> linkUnits (constraintsToToolchain pkgs unitConstraints) name;
          } else if lib.isList value then {
            inherit name;
            value =
              value
              |> map (path: path |> pathToUnitConstraints)
              |> compileUnit;
          } else if lib.isAttrs value then {
            inherit name;
            value = value;
          } else throw "")
        )
        |> lib.listToAttrs
      );
      devShells = forAllSystems (pkgs: {
      });
    };
  };
}

