{ pkgs, lib }: let
  assertOneOf = name: val: xs: (lib.assertOneOf name val xs) |> (v: if v then val else throw "");
in rec {
  mkCArguments = constraints @ {
    standard ? "c23",
    optimizationLevel ? 2,
    debuggingTarget ? "",
    debuggingLevel ? 2,
    sanitizeAddresses ? (!sanitizeKernelAddresses) && (sanitizePointerComparisons || sanitizePointerSubtraction),
    sanitizeKernelAddresses ? false,
    sanitizeThreads ? false,
    sanitizePointerComparisons ? false,
    sanitizePointerSubtraction ? false,
    sanitizeUndefinedBehaviour ? false,
    arguments ? {},
    ...
  }: let
    debuggingLevelString = debuggingLevel |> toString;
  in lib.mergeAttrs {
    overallOptions = {
      c = true;
    };
    cOptions = {
      std = assertOneOf "standard" standard [
        # c90
        "c90"
        "c89"
        "iso9899:1990"
        "iso9899:199409"
        # c99
        "c99"
        "c9x"
        "iso9899:1999"
        "iso9899:199x"
        # c11
        "c11"
        "c1x"
        "iso9899:2011"
        # c17
        "c17"
        "c18"
        "iso9899:2017"
        "iso9899:2018"
        # c23
        "c23"
        "c2x"
        "iso9899:2024"
        # c2y
        "c2y"
        # GNU 89
        "gnu90"
        "gnu89"
        # GNU 99
        "gnu99"
        "gnu9x"
        # GNU 11
        "gnu11"
        "gnu1x"
        # GNU 17
        "gnu17"
        "gnu18"
        # GNU 23
        "gnu23"
        "gnu2x"
        # GNU 2Y
        "gnu2y"
        # C++ 1998
        "c++98"
        "c++03"
        # GNU++ 1998
        "gnu++98"
        "gnu++03"
        # C++ 2011
        "c++11"
        "c++0x"
        # GNU++ 2011
        "gnu++11"
        "gnu++0x"
        # C++ 2014
        "c++14"
        "c++1y"
        # GNU++ 2014
        "gnu++14"
        "gnu++1y"
        # C++ 2017
        "c++17"
        "c++1z"
        # GNU++ 2017
        "gnu++17"
        "gnu++1z"
        # C++ 2020
        "c++20"
        "c++2a"
        # GNU++ 2020
        "gnu++20"
        "gnu++2a"
        # C++ 2023
        "c++23"
        "c++2b"
        # GNU++ 2023
        "gnu++23"
        "gnu++2b"
        # C++ 202C
        "c++2c"
        "c++26"
        # GNU++ 202C
        "gnu++2c"
        "gnu++26"
      ];
    };
    optimizationOptions = {
      "O${assertOneOf "optimizationLevel" optimizationLevel [
        1
        2
        3
        0
        "s"
        "fast"
        "g"
      ] |> toString}" = true;
    };
    debugging = {
      "g${debuggingLevelString}" = debuggingTarget == "native" || debuggingTarget == "gdb";
      "gdb${debuggingLevelString}" = debuggingTarget == "gdb";
      "dwarf-1" = debuggingTarget == "dwarf-1";
      "dwarf-2" = debuggingTarget == "dwarf-2";
      "dwarf-3" = debuggingTarget == "dwarf-3";
      "dwarf-4" = debuggingTarget == "dwarf" || debuggingTarget == "dwarf-4";
      "stabs${debuggingLevelString}" = debuggingTarget == "stabs";
      "stabsp${debuggingLevelString}" = debuggingTarget == "stabsp";
      "xcoff${debuggingLevelString}" = debuggingTarget == "xcoff";
      "xcoffp${debuggingLevelString}" = debuggingTarget == "xcoffp";
      "vmf${debuggingLevelString}" = debuggingTarget == "vmf";
    };
    instrumentationFlags = {
      sanitize = (
        (if sanitizeAddresses then ["address"] else []) ++
        (if sanitizeKernelAddresses then ["kernel-address"] else []) ++
        (if sanitizeThreads then ["thread"] else []) ++
        (if sanitizePointerComparisons then ["pointer-compare"] else []) ++
        (if sanitizePointerSubtraction then ["pointer-subtract"] else []) ++
        (if sanitizeUndefinedBehaviour then ["undefined"] else [])
      );
    };
  } arguments;
  mkCCompileArguments = constraints @ {
    include ? [],
    ...
  }: (
    lib.mergeAttrs
    (mkCArguments constraints)
    {
      overallOptions.c = true;
      overallOptions.o = "$out";
      directoryOptions.I = (lib.forEach include (x: lib.makeIncludePath [x]));
    }
  );
  mkCExecutableLinkArguments = constraints @ {
    include ? [],
    link ? [],
    ...
  }: outpath: let
  in (
    lib.mergeAttrs
    (mkCArguments constraints)
    {
      overallOptions.o = outpath;
      directoryOptions.L = (lib.forEach include (x: lib.makeLibraryPath [x]));
      linkerOptions = {
        l = link;
        Wl = if (lib.length include) > 0 then "-rpath=${lib.makeLibraryPath include}" else null;
      };
      linkerFlags = {
        # use-ld = "mold";
      };
      codeGenerationFlags = {
        PIC = true;
      };
    }
  );
  mkCSharedObjectLinkArguments = constraints @ {
    include ? [],
    link ? [],
    ...
  }: outpath: let
  in (
    lib.mergeAttrs
    (mkCArguments constraints)
    {
      overallOptions.o = outpath;
      directoryOptions.L = (lib.forEach include (x: lib.makeLibraryPath [x]));
      linkerOptions = {
        l = link;
        shared = true;
        Wl = if (lib.length include) > 0 then "-rpath=${lib.makeLibraryPath include}" else null;
      };
      linkerFlags = {
        # use-ld = "mold";
      };
      codeGenerationFlags = {
        PIC = true;
      };
    }
  );
}

