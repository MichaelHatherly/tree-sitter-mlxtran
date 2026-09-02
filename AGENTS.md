# Project instructions for AI assistants

## Changelog

Any change a consumer of the grammar or the bindings would notice gets an entry
under `## [Unreleased]` in `CHANGELOG.md`, in the same commit as the change
itself. The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Node names and tree structure count as public interface. A rename, or a change
to the shape of the tree, breaks every downstream query while every signature
still compiles, so those always get an entry under `Changed` or `Removed`.

CI configuration, dependency bumps for dev tooling, and repository housekeeping
get no entry.

## Releases

The version appears in six files and they move together:

- `Cargo.toml`
- `CMakeLists.txt`
- `Makefile`
- `package.json`
- `pyproject.toml`
- `tree-sitter.json`

A release renames `## [Unreleased]` to the new version with the date, adds the
compare link at the foot of `CHANGELOG.md`, and leaves an empty `Unreleased`
section behind. Pushing a `v*` tag on the merged bump commit is what triggers
the PyPI upload; nothing publishes on a plain push to main.

## Generated files

Everything under `src/` is written by `tree-sitter generate` from `grammar.js`
and committed. Never hand-edit it. CI regenerates and fails if the result
differs, so run the generator after every grammar change. The `README.md`
Development section covers the rest of the loop, including the CLI version pin
that `package.json` and `.github/workflows/ci.yml` both carry.
