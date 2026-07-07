# MlxtranTypst

Convert Monolix mlxtran equations to typst math source, via TreeSitter.jl and
this grammar.

## Prerequisite

TreeSitter.jl loads an already-compiled grammar library. Build it once from the
repo root:

```sh
tree-sitter build      # writes mlxtran.dylib / mlxtran.so (gitignored)
```

## Use

```julia
using MlxtranTypst

mlxtran_to_typst("EQUATION:\nddt_I = beta*T*I - dI*I")
# "\$(dif I)/(dif t) = beta dot T dot I - \"dI\" dot I\$"
```

`mlxtran_to_typst(source)` returns one typst math block (`$...$`) per equation,
one per line. Wrap the lines in a typst document and run `typst compile` to
render. `equation_to_typst(node, source)` converts a single assignment or
expression subtree.

## Rendering conventions

- Multiplication renders as `dot` (centered dot).
- ODE targets `ddt_X` render as `(dif X)/(dif t)`.
- Greek names map to symbols, including camelCase prefixes: `alphaE` -> `alpha_E`.
- Underscore tails become subscripts: `beta_prime_exp` -> `beta_("prime,exp")`.
- Multi-letter non-greek names are quoted so typst renders them literally.
- `list`-valued assignments (INPUT/OUTPUT config) are skipped.
