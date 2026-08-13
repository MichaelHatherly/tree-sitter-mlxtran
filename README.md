# tree-sitter-mlxtran

[![CI][ci-badge]](https://github.com/MichaelHatherly/tree-sitter-mlxtran/actions/workflows/ci.yml)

A [tree-sitter](https://github.com/tree-sitter/tree-sitter) grammar for
mlxtran, the model description language used by
[Monolix](https://monolix.lixoft.com) and the rest of the MonolixSuite.

It parses both project files (`.mlxtran`) and the model files they reference,
which conventionally carry a `.txt` extension.

## What it covers

- Angle sections (`<MODEL>`) and the square sections they contain (`[LONGITUDINAL]`)
- `DESCRIPTION:` free text and label blocks such as `input:` or `EQUATION:`
- Statements: assignments, `if`/`elseif`/`else`, and task calls with keyword arguments
- Expressions: arithmetic and logical operators, comparisons, calls, derivatives
  (`ddt_Ac`), brace lists with `key = value` pairs and bare hyphenated flags

## Usage

The grammar ships bindings for C, Rust, Node and Python.

```rust
let mut parser = tree_sitter::Parser::new();
parser.set_language(&tree_sitter_mlxtran::LANGUAGE.into())?;
```

```python
from tree_sitter import Language, Parser
import tree_sitter_mlxtran

parser = Parser(Language(tree_sitter_mlxtran.language()))
```

## Development

```sh
npm install          # install the tree-sitter CLI and dev tooling
npx tree-sitter generate
npx tree-sitter test # run the corpus in test/corpus
npm run lint         # check grammar.js
```

`src/parser.c` is generated and committed. CI regenerates it and fails if the
result differs, so run `tree-sitter generate` after every change to
`grammar.js`. The CLI version is pinned in both `package.json` and
`.github/workflows/ci.yml`; keep them in step.

[ci-badge]: https://img.shields.io/github/actions/workflow/status/MichaelHatherly/tree-sitter-mlxtran/ci.yml?logo=github&label=CI
