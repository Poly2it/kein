{ lib, plib, ... }:

{
  makeSourceFromGenerator = toolchain: sources: arguments: {
    derivation = let
      source = sources |> lib.lists.head;
    in plib.makeShellBuilder {
      name = "generated";
      system = toolchain.system;
      commands = ''
        ${map (path:
          ''
          mkdir -p ${
            path
            |> plib.parentPath
            |> plib.dropStorePrefix
            |> lib.strings.escapeShellArg
          }
          cp ${path} ${
            path
            |> plib.dropStorePrefix
            |> toString
            |> lib.strings.escapeShellArg
          } || exit 1
          ''
        ) sources |> lib.strings.concatStringsSep "\n"}
        ${toolchain.makeSourceFromGeneratorCommand toolchain source arguments}
      '';
      outputs = ["out"];
    };
  };
  backends = {
    luajit = import ./luajit.nix { inherit lib plib; };
  };
}

