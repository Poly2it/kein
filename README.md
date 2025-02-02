<p align="center"><image width="40%" src="./doc/logo.svg"/></p>

<p align="center"><i>Kein</i> is a contemporary build system centered around Nix.</p>

## Pitch
Setting up a flake with a C program runnable using `nix run` on x86_64 and
aarch64 Linux and Darwin:
```nix
{
  description = "My kein flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    kein = {
      url = "https://github.com/Poly2it/kein.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { kein, ... }: kein.flakeFromKeinexpr {
    bin = rec {
      main = ./main.c;
      default = main;
    };
  };
}
```

Kein is currently in unstable alpha.

## Rationale
First and foremost, I do not think any of the existing build systems are
good enough. Makefiles have been my go-to option for configuring project builds
up until now. They mostly suffice and are much faster, simpler and less
abstract than CMake or Bazel builds, but still have some hurdles.

- Third-party software is required to achieve basic functionality like
  automatic rebuilds of files dependent on modified headers.
- The syntax gets cluttery fast.
- They require too much boilerplate.
- People resort to nonstandard implementations to resolve the complications.
- Effort is required to have them work with Nix.

Additionally, beyond the scope of Makefiles, other traits may be sought after in
new build systems, like determinism, better caching and more options for
build-time programmability.

Nix already offers wrappers for building projects using existing build systems,
but that forms another abstraction, and the subordinate issues are not resolved.
The pain points still don't end, as Nix is not compatible with the mutable
stores used in traditional build systems. A build which fails at 95% has to
restart from zero for every attempt at a patch. In practice, the wrappers are
not used in development, only in publishing. Developers use dev shells to
work outside of the deterministic build environment. After achieving a
successful build in the dev shell, Nix may be set up to wrap the build system
to verify determinism. This solution does not allow Nix to provide any value to
new projects built with Nix in mind.

Kein is not a build system in the same sense as the aforementioned. Kein
provides build-oriented interfaces around Nix to allow building all parts of
your programs for Nix directly. Every object is built separately and stored
indefinitely as a derivation, allowing fast iteration times. Nix builds your
projects without a build system.

## Documentation
### Project Derivation
Kein flakes automatically get a "default" derivation, a project derivation,
which contains the files specified in the Kein expression. By default, the main
program is the same as the name (`meta.name`) of the kein expression.

### Linkage
#### Inferred linkage
The linkage formula will by default be inferred by the constraint expressions
used in the linkage expression.

#### Explicit linkage
The linkage forumla can be written expressly using `<backend>` as a functor.

```nix
./main.c |> gcc
```

### Constraint API
The compilation of an output is configured via constraints. A constraint takes
a `constraintExpr`, that is either another constraint, a path or a list of
`constraintExprs`, and outputs a new `constraint` depending on the constraint
function used. A constraint may represent a single compilation unit, or a
collection of units, for example when linking multiple units via the GCC
backend.

Different backends have different constraints. To access a backend, write your
output (bin, lib, etc.) as a function taking a set:

```nix
bin = { gcc, ... }: rec {
  main = ./main.c;
  default = main;
};
```

`gcc` is now the API for the `gcc` backend. We are additionally given optional
access to `pkgs` and `system`. We can now set compilation options, for example
including the raylib headers and linking raylib:

```nix
bin = { gcc, pkgs, ... }: rec {
  main =
    ./main.c
    |> gcc.include pkgs.raylib
    |> gcc.link "raylib";
  default = main;
};
```

If the constraint is acting on a list of `constraintExprs`, the constraint will
propagate to all inner constraints. To except an inner `constraintExpr`, the
inverse, or another value on the excepted expression:

```nix
bin = { gcc, pkgs, ... }: rec {
  main =
    [
      ./a.c
      (./b.c |> gcc.setPositionIndependent false)
    ]
    |> gcc.setPositionIndependent true
    |> gcc.include pkgs.raylib
    |> gcc.link "raylib";
  default = main;
};
```

### Metadata and Special Files
Metadata can be added to Kein expressions to attach information to build inputs.
The data is added to the meta top-level attribute, which is either a set or
function taking an attribute set containing `lib` and `pkgs`:

```nix
meta = { lib, ... }: {
  name = "A Name";
  license = lib.licenses.lgpl3;
};
```

#### Special Files
A license file can be added to the top-level attribute `licenseFile`. It will
be added to the project derivations. Multiple licenses can be attached as a list
in `licenseFiles`. Other files can be added to `distributedFiles`:

```nix
licenseFile = ./LICENSE;
distributedFiles = [
  ./NOTES.txt
];
```

### `gcc.include <package/packages>`
Where package is a derivation, makes its `include` directory searchable during
object compilation, and `lib` searchable during linkage.

### `gcc.link <name/names>`
Links `name` as in `-l<name>` during compilation.

### `gcc.define <key> <value>`
Defines `key` as a compile-time macro `name`.

### `gcc.setPositionIndependent <bool>`
Sets the `positionIndependent` constraint to `bool`. If the unit is compiled to
an executable, `-fPIE` will be used. If the unit is compiled to an archive
`-fPIC` is used.

### `gcc.setOptimizeLevel <value>`
Sets the optimization level to `value`. Equivalent to `-O<value>`.

### `gcc.setDebugSymbols <bool>`
Decides whether debug symbols should be enabled. Equivalent to `-g`.

### `gcc.sanitizeAddresses <bool>`
Decides whether AddressSanitizer should be enabled and set to sanitise
addresses.

### `gcc.sanitizePointerComparisons <bool>`
Decides whether AddressSanitizer should be set to sanitise pointer comparisons
between unrelated objects. Will also enable `sanitizeAddresses`.

### `gcc.setStandard <value>`
Set the language standard revision to `value`. Equivalent to `-std=<value>`.

### `gcc.debug`
Enables an assortent of options tailored towards debuggable builds. Includes
AddressSanitizer.

