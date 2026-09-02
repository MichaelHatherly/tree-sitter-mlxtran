# Project instructions for AI assistants

A tree-sitter grammar for mlxtran, the Monolix model description language. The
`README.md` covers what the grammar parses and the development loop; this file
covers what an agent has to keep in step.

## Grammar changes

Start with a case in `test/corpus/`, then run `npx tree-sitter generate` and
`npx tree-sitter test`. The generated `src/parser.c` is committed, and CI
regenerates it and fails on any difference.

`src/scanner.c` is the exception to that: it is hand-written and implements the
`description_text` external token, which reads `DESCRIPTION:` free text a line
at a time so the block ends at the next structural header. `tree-sitter
generate` never touches it. Change it when the external token's behaviour needs
to change, and leave the rest of `src/` alone.

CI also parses every file in `examples/` with `tree-sitter parse`. Those are
real Monolix project and model files, so a change can pass the corpus and still
fail there. Run `npx tree-sitter parse -q examples/*` before pushing; it prints
nothing and exits 0 when every file parses clean.

Renaming a node means updating `queries/highlights.scm` in the same change. The
corpus tests only check the tree, so a query that no longer matches anything
stays green.

The tree-sitter CLI version is pinned in two places, `tree-sitter-cli` in
`package.json` and `tree-sitter-ref` in `.github/workflows/ci.yml`. A mismatch
writes a different `src/parser.c` and fails the generate check. The files under
`bindings/` come from that CLI's templates; when they drift, realign them with
the templates for the pinned version rather than hand-patching.

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

`.github/workflows/publish.yml` is registered by filename as the PyPI trusted
publisher, along with the `pypi` environment it declares. Renaming either
breaks publishing until the publisher is registered again.
