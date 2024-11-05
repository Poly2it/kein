# Kein
*Kein* is a contemporary build system centered around Nix.

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
```nix
{
  toolchain = (langs.c.backends.gcc.makeToolchain ./. {});

  hello = (
    langs.c.makeExecutable
    toolchain
    {}
    [
      (langs.c.makeTranslationUnit toolchain {} ./main.c)
    ]
    "hello"
  );
}
```
*Please refer to [the example](example/flake.nix) for a full solution.*

This is the code necessary to configure a *hello world* project.
`langs.c.makeExecutable` is a function which takes a *toolchain* attrset, an
*options* attrset, a list of translation units and finally the name of the
resulting executable. It returns an attrset containing the derivation and some
metadata. The only translation unit in this case is *main*. It is similarly
configured using `langs.c.makeTranslationUnit`, which takes the *toolchain*,
*options* and *path* of the source. It also builds an attrset containing the
derivation and some metadata.

The toolchain is shared (as a rule) between all objects. It contains the core
packages and functions used for deciding how every derivation should be built.
Most importantly, `cc`, `ccOptions`, `ld` and `ldOptions`. `ccOptions`, the C
compiler options, sets the features, machine and optimisation settings used
when, in this case, the GCC backend compiles the source.

The top-level *options* mostly handle settings which cannot be deduced from
other parts of the program, such as the libraries to link or derivations whose
headers should be made available during the compilation of a translation unit.

All languages and backends will be thoroughly documented once settled later in
development.

---

<img src="docs/lgpl.svg" alt="drawing" width="200" align="right"/>

Kein is free software, licensed under the LGPL-3.0 license.

