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
    flakeFromKeinexpr = { bin ? {} }: {
      overlays.default = final: prev: {
      };
      packages = forAllSystems (pkgs: system: let
        lib = pkgs.lib // {
          fpath = (import ./lib/fpath.nix { inherit lib; });
          header = (import ./lib/header.nix { inherit lib; });
          builders = (import ./lib/builders.nix { inherit lib pkgs system; });
          constraints = (import ./lib/constraints.nix { inherit lib pkgs system backends; });
        };
        backends = (import ./backends { inherit lib pkgs; });
        api = (import ./api { inherit lib pkgs; });
      in
        (if builtins.isFunction bin then
          (bin { inherit pkgs system; gcc = api.gcc; })
        else
          bin)
        |> lib.attrsToList
        |> map ({ name, value }: {
          inherit name;
          value = (lib.constraints.toExecutable name (lib.constraints.resolveConstraint value));
        })
        |> lib.listToAttrs
      );
      devShells = forAllSystems (pkgs: {
      });
    };
  };
}

