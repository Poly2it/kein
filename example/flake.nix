{
  description = "Kein example flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    kein.url = "github:Poly2it/kein";
  };

  outputs = { nixpkgs, kein, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    langs = kein.langs;
    toolchain = (langs.c.backends.gcc.makeToolchain pkgs ./.);

    hello = (
      langs.c.makeExecutable
      toolchain
      {}
      [
        (langs.c.makeTranslationUnit toolchain {} ./main.c)
      ]
      "hello"
    );
  in {
    packages.x86_64-linux.default = hello.derivation;
    packages.x86_64-linux.propagateCompileCommands = kein.langs.c.makeCompileCommandsPropagator toolchain hello.translationUnits;
  };
}

