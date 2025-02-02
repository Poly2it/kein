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
    flakeFromKeinexpr = keinexpr @ { bin ? {}, meta ? {}, distributedFiles ? [], ... }: {
      overlays.default = final: prev: {
      };
      packages = forAllSystems (pkgs: system: let
        lib = pkgs.lib // {
          fpath = (import ./lib/fpath.nix { inherit lib; });
          header = (import ./lib/header.nix { inherit lib; });
          builders = (import ./lib/builders.nix { inherit lib pkgs system; });
          constraints = (import ./lib/constraints.nix { inherit lib pkgs system backends; });
        };
        noop = x: x;
        backends = (import ./backends { inherit lib pkgs; });
        api = (import ./api { inherit lib pkgs; });
        resolvedMeta = if lib.isFunction meta then meta { inherit pkgs lib; } else meta;
        sharedMeta =
          {}
          |> (if lib.hasAttr "license" resolvedMeta then (x: lib.setAttr x "license" resolvedMeta.license) else noop);
        binPackages =
          (if builtins.isFunction bin then
            (bin { inherit pkgs system; gcc = api.gcc; })
          else
            bin)
          |> lib.attrsToList
          |> map ({ name, value }: {
            inherit name;
            value = (lib.constraints.toExecutable name (value |> lib.constraints.setUnsetConstraints {
              meta = sharedMeta;
            }));
          })
          |> lib.listToAttrs;
        outputsBin = (binPackages |> lib.attrsToList |> lib.length) > 0;
        licenseFiles =
          if lib.hasAttr "licenseFiles" keinexpr then
            keinexpr.licenseFiles
          else if lib.hasAttr "licenseFile" keinexpr then let
            licenseFile = keinexpr.licenseFile |> lib.fpath.mkFpath;
          in {
            ${licenseFile |> lib.fpath.fileName} = licenseFile |> lib.fpath.toPath;
          } else {};
        resovledDistributedFiles =
          distributedFiles
          |> map (path: { name = path |> lib.fpath.mkFpath |> lib.fpath.fileName; value = path; })
          |> lib.listToAttrs;
        name = if lib.hasAttr "name" resolvedMeta then resolvedMeta.name else "default";
      in
        binPackages // {
          "default" = lib.builders.keinDerivation {
            inherit name;
            command = ''
              mkdir -p $out
              ${licenseFiles |> lib.mapAttrsToList (name: value: "cp ${value} $out/${name}") |> lib.concatStringsSep "\n"}
              ${resovledDistributedFiles |> lib.mapAttrsToList (name: value: "cp ${value} $out/${name}") |> lib.concatStringsSep "\n"}
              ${if outputsBin then "mkdir -p $out/bin" else ""};
              ${binPackages |> lib.mapAttrsToList (name: value: "cp ${value |> lib.getExe} $out/bin/${name}") |> lib.concatStringsSep "\n"}
            '';
            kein = {};
            meta = sharedMeta // {
              mainProgram = name;
            };
          };
        }
      );
      devShells = forAllSystems (pkgs: {
      });
    };
  };
}

