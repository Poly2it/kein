## Documentation
### Compilation

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

### `gcc.include <package>`
Where package is a derivation, makes its `include` directory searchable during
object compilation, and `lib` searchable during linkage.

### `gcc.link <name>`
Links `name` as in `-l<name>` during compilation.

### `gcc.setPositionIndependent <bool>`
Sets the `positionIndependent` constraint to `bool`. If the unit is compiled to
an executable, `-fPIE` will be used. If the unit is compiled to an archive
`-fPIC` is used.

