from unittest import TestCase

from tree_sitter import Language, Parser

import tree_sitter_mlxtran


class TestLanguage(TestCase):
    def test_can_load_grammar(self):
        try:
            Parser(Language(tree_sitter_mlxtran.language()))
        except Exception:
            self.fail("Error loading Mlxtran grammar")

    def test_can_parse_a_model(self):
        parser = Parser(Language(tree_sitter_mlxtran.language()))
        tree = parser.parse(b"[LONGITUDINAL]\ninput = {ka, V, Cl}\n")
        self.assertFalse(tree.root_node.has_error)
