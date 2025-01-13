{ pkgs, lib, plib, ... }:

let
  ilib = import ./ilib.nix { inherit lib plib; };
in {
  makeTranslationUnit = toolchain: opts @ { includes ? [], generatedSource ? {} }: path: let
    file = path |> plib.dropStorePrefix;
    compileCommand = toolchain.makeCompileCommand toolchain opts path;
    resolvedIncludedHeaders = ilib.recursiveResolvedIncludes generatedSource toolchain.projectRoot file;
    resolvedIncludedSource =
      resolvedIncludedHeaders
      |> lib.filter (x: !builtins.hasAttr x generatedSource);
    resolvedIncludedGeneratedSource =
      resolvedIncludedHeaders
      |> lib.filter (x: builtins.hasAttr x generatedSource)
      |> map (x: { name = x; value = generatedSource.${x}.derivation; })
      |> builtins.listToAttrs;
    /* includedSourceHeaders actually includes generated headers aaaaaaaaaaaa */
  in {
    inherit includes generatedSource toolchain file;
    compileCommand = compileCommand |> plib.splitShellArgs;
    name = (ilib.makeObjectName path);
    derivation = plib.makeShellBuilder {
      name = (ilib.makeObjectName path);
      system = toolchain.system;
      # The compilation process copies exactly the local files needed to
      # compile the translation unit with exactly the same file hierarchy as
      # in the source.
      commands = ''
        set -e
        mkdir -p ./${
          path
          |> plib.parentPath
          |> plib.dropStorePrefix
          |> lib.strings.escapeShellArg
        }
        cp ${path} ${
          path
          |> plib.dropStorePrefix
          |> lib.strings.escapeShellArg
        }
        ${
          resolvedIncludedGeneratedSource
          |> builtins.mapAttrs (name: path: ''
            mkdir -p ./${name |> plib.parentName |> lib.strings.escapeShellArg}
            cp ${path}/generated ${name}
          '')
          |> builtins.attrValues
          |> lib.concatStringsSep "\n"
        }
        ${
          resolvedIncludedSource
          |> map (name: ''
            mkdir -p ./${name |> plib.parentName |> lib.strings.escapeShellArg}
            cp ${name |> plib.toRelativePath toolchain.projectRoot} ${name}
          '')
          |> lib.concatStringsSep "\n"
        }
        echo ${compileCommand}
        ${compileCommand}
      '';
      outputs = ["out"];
    };
  };
  makeExecutable = toolchain: opts @ { links ? [] }: translationUnits: name: {
    inherit name links translationUnits;
    generatedSource = map (x: x.generatedSource) translationUnits |> lib.attrsets.mergeAttrsList;
    derivation = plib.makeShellBuilder {
      inherit name;
      system = toolchain.system;
      commands = ''
        mkdir $bin/bin
        echo ${toolchain.makeLinkCommand toolchain opts translationUnits name}
        ${toolchain.makeLinkCommand toolchain opts translationUnits name}
      '';
      outputs = ["bin"];
    };
  };
  makeLibrary = toolchain: opts @ {}: translationUnits: name: {
    inherit name translationUnits;
    generatedSource = map (x: x.generatedSource) translationUnits |> lib.attrsets.mergeAttrsList;
    derivation = plib.makeShellBuilder {
      inherit name;
      system = toolchain.system;
      commands = ''
        mkdir $out/lib
        ${toolchain.ar} -rcs ${
          translationUnits
            |> map (x: "${x.derivation}/${x.name}"
              |> lib.strings.escapeShellArg
            )
            |> lib.concatStringsSep " "
        } ${name}
      '';
      outputs = ["out"];
    };
  };
  makeGeneratedSourcePropagator = toolchain: generatedSource: plib.makeShellBuilder {
    name = "generatedSourcePropagator";
    system = toolchain.system;
    commands = ''
      mkdir $bin/bin
      cat > $bin/bin/generatedSourcePropagator <<"EOF"
      #!/bin/sh
      set -e

      clear() {
        ${
          generatedSource
          |> builtins.mapAttrs (name: _: let
            escapedName = name |> lib.strings.escapeShellArg;
          in ''
            mkdir -p ./${name |> plib.parentName |> lib.strings.escapeShellArg}
            if [ -f ${escapedName} ] && [ $(stat -c %a ${escapedName}) -ne 444 ]; then
              echo Not overwriting file ${escapedName} as it exists and is mutable.
            else
              rm -f ${escapedName}
            fi
          '')
          |> builtins.attrValues
          |> lib.concatStringsSep "\n"
        }
      }

      options=$(getopt -n generatedSourcePropagator -l "clear" -o "c" -- "$@")
      eval set -- "$options"
      while true; do
        case "$1" in
        -c|--clear)
          clear
          exit 0
          ;;
        --)
          break;;
        esac
        shift
      done

      ${
        generatedSource
        |> builtins.mapAttrs (name: generated: let
          escapedName = name |> lib.strings.escapeShellArg;
        in ''
          mkdir -p ./${name |> plib.parentName |> lib.strings.escapeShellArg}
          if [ -f ${escapedName} ] && [ $(stat -c %a ${escapedName}) -ne 444 ]; then
            echo Not overwriting file ${escapedName} as it exists and is mutable.
          else
            install -m 444 -T ${generated.derivation}/generated ${escapedName}
          fi
        '')
        |> builtins.attrValues
        |> lib.concatStringsSep "\n"
      }

      EOF
      chmod 755 $bin/bin/generatedSourcePropagator
    '';
    outputs = ["bin"];
  };
  makeCompileCommandsPropagator = toolchain: translationUnits: plib.makeShellBuilder {
    name = "compileCommandsPropagator";
    system = toolchain.system;
    commands = let
      includes =
        translationUnits
        |> map (unit:
          unit.includes
        )
        |> lib.lists.flatten;
      buildsys =
        translationUnits
        |> map (unit:
          [
            unit.toolchain.cc
            unit.toolchain.ld
          ]
        )
        |> lib.lists.flatten;
      dependencies =
        (includes ++ buildsys)
        |> lib.lists.unique;
    in ''
      mkdir $bin/bin
      cat > $bin/bin/compileCommandsPropagator <<"EOF"
      #!/bin/sh
      echo -n "[" > compile_commands.json
      ${translationUnits |> map (unit:
        {
          arguments = unit.compileCommand;
          directory = ".";
          file = unit.file;
          output = unit.name;
        }
        |> builtins.toJSON
        |> lib.strings.escapeShellArg
        |> (x: "echo -n ${x}, >> compile_commands.json")
      ) |> lib.strings.concatStringsSep "\n"}
      echo -n "]" >> compile_commands.json
      _NIXMAKE_COMPILE_DATABASE_SED_PATH=$(printf '%s\n' "$(pwd)" | sed -e 's/[\/&]/\\&/g')
      sed -i -e "s/\"directory\":\".\"/\"directory\":\"$_NIXMAKE_COMPILE_DATABASE_SED_PATH\"/g" compile_commands.json
      unset _NIXMAKE_COMPILE_DATABASE_SED_PATH

      clean() {
        rm -f compile_commands.json
      }
      trap "clean" KILL INT
      echo -n "Refreshed compile_commands.json, "
      echo ${toString (lib.lists.length dependencies)} ${
        if (lib.lists.length dependencies) == 1 then
          "dependency"
        else
          "dependencies"
      }:
      echo ${
        dependencies
        |> lib.strings.concatStringsSep "\n"
        |> lib.strings.escapeShellArg
      }
      sleep infinity

      EOF
      chmod 755 $bin/bin/compileCommandsPropagator
    '';
    outputs = ["bin"];
  };
  backends = {
    gcc = import ./gcc.nix { inherit pkgs lib plib ilib; };
  };
}

