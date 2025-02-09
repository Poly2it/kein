{ pkgs, lib, ... }:

{
  toCommand = {
    gcc ? "${pkgs.gcc}/bin/gcc",
    overallOptions ? {},
    overallFlags ? {},
    cOptions ? {},
    cFlags ? {},
    cppFlags ? {},
    objcObjcppFlags ? {},
    diagnosticFlags ? {},
    overallWarnings ? {},
    warningOptions ? {},
    cObjcWarnings ? {},
    debugging ? {},
    debuggingFlags ? {},
    optimizationOptions ? {},
    optimizationFlags ? {},
    instrumentationOptions ? {},
    instrumentationFlags ? {},
    preprocessorOptions ? {},
    preprocessorFlags ? {},
    assemblerOptions ? {},
    linkerFlags ? {},
    linkerOptions ? {},
    directoryOptions ? {},
    codeGenerationFlags ? {},
  }: infiles: (
    (import ./to_command.nix { inherit lib; })
    gcc
    overallOptions
    overallFlags
    cOptions
    cFlags
    cppFlags
    objcObjcppFlags
    diagnosticFlags
    overallWarnings
    warningOptions
    cObjcWarnings
    debugging
    debuggingFlags
    optimizationOptions
    optimizationFlags
    instrumentationOptions
    instrumentationFlags
    preprocessorOptions
    preprocessorFlags
    assemblerOptions
    linkerFlags
    linkerOptions
    directoryOptions
    codeGenerationFlags
  ) infiles;
}

