#include "tree_sitter/parser.h"

#include <stdbool.h>

enum TokenType {
  DESCRIPTION_TEXT,
};

void *tree_sitter_mlxtran_external_scanner_create(void) { return NULL; }
void tree_sitter_mlxtran_external_scanner_destroy(void *payload) {}
unsigned tree_sitter_mlxtran_external_scanner_serialize(void *payload, char *buffer) { return 0; }
void tree_sitter_mlxtran_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {}

static inline bool is_ident_start(int32_t c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_';
}

static inline bool is_ident_part(int32_t c) {
  return is_ident_start(c) || (c >= '0' && c <= '9');
}

// A description line is any line of free text that is not a section header
// (`[...]`, `<...>`) and not a label header (`WORD:`). Emitted one line at a
// time so the enclosing block ends cleanly at the next structural header.
bool tree_sitter_mlxtran_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  if (!valid_symbols[DESCRIPTION_TEXT]) {
    return false;
  }

  // Skip whitespace, including blank lines, to reach the next line of text.
  // These advances are rolled back when the scan returns false.
  while (lexer->lookahead == ' ' || lexer->lookahead == '\t' ||
         lexer->lookahead == '\n' || lexer->lookahead == '\r') {
    lexer->advance(lexer, true);
  }

  // Section header or end of file: no description text here.
  if (lexer->eof(lexer) || lexer->lookahead == '[' || lexer->lookahead == '<') {
    return false;
  }

  // Reject a label header line (`WORD:`). Advancing here is rolled back when we
  // return false, so it is safe to look ahead.
  if (is_ident_start(lexer->lookahead)) {
    while (is_ident_part(lexer->lookahead)) {
      lexer->advance(lexer, false);
    }
    while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
      lexer->advance(lexer, false);
    }
    if (lexer->lookahead == ':') {
      return false;
    }
  }

  // Consume the rest of the line as description text.
  bool has_content = false;
  while (!lexer->eof(lexer) && lexer->lookahead != '\n' && lexer->lookahead != '\r') {
    lexer->advance(lexer, false);
    has_content = true;
  }

  if (!has_content) {
    return false;
  }

  lexer->mark_end(lexer);
  lexer->result_symbol = DESCRIPTION_TEXT;
  return true;
}
