"""Checks that only hold for a built wheel or sdist, not an editable install.

An editable install points at the source tree, where the queries still live at
the repository root, so these run against installed distributions only.
"""

from unittest import TestCase

from tree_sitter import Language, Parser, Query

import tree_sitter_mlxtran


class TestDistribution(TestCase):
    def test_ships_the_highlight_query(self):
        query = tree_sitter_mlxtran.HIGHLIGHTS_QUERY
        self.assertIsNotNone(query, "highlight query missing from the distribution")
        Query(Language(tree_sitter_mlxtran.language()), query)

    def test_ships_type_information(self):
        from importlib.resources import files

        package = files("tree_sitter_mlxtran")
        self.assertTrue((package / "py.typed").is_file())
        self.assertTrue((package / "__init__.pyi").is_file())
