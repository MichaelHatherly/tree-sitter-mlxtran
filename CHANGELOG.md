# Changelog

All notable changes to this project are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Node names and tree structure count as public interface, so renames and changes
to the shape of the tree are always listed. They break downstream queries
without breaking any signature.

## [Unreleased]

### Added

- Grammar for mlxtran project files and the model files they reference: angle
  sections such as `<MODEL>`, the square sections they contain, `DESCRIPTION:`
  free text, and label blocks such as `input:` or `EQUATION:`.
- Statements: assignments, `if`/`elseif`/`else`, and task calls with keyword
  arguments.
- Expressions: arithmetic, logical and comparison operators, calls, derivatives
  such as `ddt_Ac`, and brace lists holding `key = value` pairs and bare
  hyphenated flags.
- `queries/highlights.scm`, exposed to Python consumers as `HIGHLIGHTS_QUERY`.
- Bindings for C, Node, Python and Rust.

[Unreleased]: https://github.com/MichaelHatherly/tree-sitter-mlxtran/commits/main
