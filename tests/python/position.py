"""Exercise the generated Position API through PyGObject.

This deliberately uses only introspected constructors, fields, and variants.
It verifies that the typelib remains usable in addition to testing the same
wire representation as the native Vala suite.
"""

# PyGObject namespaces are generated at runtime and do not provide .pyi files.
# pyright: reportMissingImports=false

import unittest
from typing import TYPE_CHECKING

import gi

gi.require_version("Lsp", "3.0")

from gi.repository import GLib  # pyright: ignore[reportAttributeAccessIssue]

if TYPE_CHECKING:
    import lsp_typing as Lsp
else:
    from gi.repository import Lsp  # pyright: ignore[reportAttributeAccessIssue]


class PositionTest(unittest.TestCase):
    def test_round_trip(self) -> None:
        original = Lsp.Position()
        original.init(3, 4)

        decoded = Lsp.Position()
        decoded.init_from_variant(original.to_variant())

        self.assertEqual(decoded.line, 3)
        self.assertEqual(decoded.character, 4)

    def test_signed_json_values(self) -> None:
        encoded = GLib.Variant(
            "a{sv}",
            {
                "line": GLib.Variant("x", 8),
                "character": GLib.Variant("x", 20),
            },
        )

        decoded = Lsp.Position()
        decoded.init_from_variant(encoded)

        self.assertEqual(decoded.line, 8)
        self.assertEqual(decoded.character, 20)


if __name__ == "__main__":
    unittest.main()
