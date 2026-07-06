/**
 * @file Tree-sitter grammar for Monolix mlxtran files
 * @author Michael Hatherly <michaelhatherly@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

/** Comma-separated list of `rule`, no trailing separator. */
const commaSep = rule => optional(seq(rule, repeat(seq(",", rule))));

module.exports = grammar({
  name: "mlxtran",

  extras: $ => [/[ \t\r\n]/, $.comment],

  externals: $ => [$.description_text],

  rules: {
    source_file: $ => repeat($._item),

    _item: $ => choice(
      $.angle_section,
      $.square_section,
      $.description_block,
      $.label_block,
      $._statement,
    ),

    angle_section: $ => prec.right(seq(
      "<", field("name", $.section_name), ">",
      repeat(choice($.square_section, $.description_block, $.label_block, $._statement)),
    )),

    square_section: $ => prec.right(seq(
      "[", field("name", $.section_name), "]",
      repeat(choice($.description_block, $.label_block, $._statement)),
    )),

    description_block: $ => seq(alias(token("DESCRIPTION:"), $.block_name), repeat($.description_text)),

    label_block: $ => prec.right(seq(
      field("name", $.block_name),
      repeat($._statement),
    )),

    section_name: $ => /[A-Za-z_][A-Za-z0-9_]*/,
    block_name: $ => token(/[A-Za-z_][A-Za-z0-9_]*:/),

    _statement: $ => choice($.assignment, $.if_statement, $.expression_statement),

    if_statement: $ => prec.right(seq(
      "if", field("condition", $._condition),
      repeat($._statement),
      repeat($.elseif_clause),
      optional($.else_clause),
      "end",
    )),

    elseif_clause: $ => seq(
      "elseif", field("condition", $._condition),
      repeat($._statement),
    ),

    else_clause: $ => seq("else", repeat($._statement)),

    _condition: $ => choice($._expression, $.comparison),

    comparison: $ => prec.left(seq(
      field("left", $._expression),
      field("operator", choice("<", ">", "<=", ">=", "==", "!=", "~=")),
      field("right", $._expression),
    )),

    assignment: $ => seq(
      field("target", choice($.derivative, $.identifier)),
      "=",
      field("value", $._expression),
    ),

    expression_statement: $ => $._expression,

    _expression: $ => choice(
      $.binary_expression,
      $.unary_expression,
      $._primary,
    ),

    _primary: $ => choice(
      $.call,
      $.parenthesized_expression,
      $.list,
      $.string,
      $.number,
      $.identifier,
    ),

    parenthesized_expression: $ => seq("(", choice($._expression, $.comparison), ")"),

    binary_expression: $ => {
      const left = [
        ["||", 1], ["|", 1],
        ["&&", 2], ["&", 2],
        ["+", 4], ["-", 4],
        ["*", 5], ["/", 5],
      ];
      return choice(
        ...left.map(([op, p]) => prec.left(p, seq(
          field("left", $._expression),
          field("operator", op),
          field("right", $._expression),
        ))),
        prec.right(7, seq(
          field("left", $._expression),
          field("operator", "^"),
          field("right", $._expression),
        )),
      );
    },

    unary_expression: $ => prec(6, seq(
      field("operator", choice("-", "+", "!", "~")),
      field("operand", $._expression),
    )),

    list: $ => seq("{", optional(seq(
      $._list_element,
      repeat(seq(optional(","), $._list_element)),
      optional(","),
    )), "}"),

    _list_element: $ => choice($.pair, $._expression),

    pair: $ => seq(
      field("key", choice($.call, $.identifier, $.string, $.number)),
      "=",
      field("value", $._expression),
    ),

    call: $ => prec(8, seq(
      field("function", $.identifier),
      field("arguments", $.arguments),
    )),

    arguments: $ => seq(token.immediate("("), commaSep(choice($.pair, $.comparison, $._expression)), ")"),

    derivative: $ => token(prec(1, /ddt_[A-Za-z_][A-Za-z0-9_]*/)),

    identifier: $ => /[A-Za-z_][A-Za-z0-9_]*/,

    number: $ => /(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?/,

    string: $ => /'[^']*'/,

    comment: $ => /;[^\n]*/,
  }
});
