"""Verify that Jedi follows the static aliases used by pylsp."""

import unittest
from pathlib import Path

import jedi


class PylspAnalysisTest(unittest.TestCase):
    def complete(self, source: str) -> set[str]:
        lines = source.splitlines()
        project_dir = Path(__file__).parent
        project = jedi.Project(project_dir)
        completions = jedi.Script(
            source,
            path=project_dir / "analysis_probe.py",
            project=project,
        ).complete(len(lines), len(lines[-1]))
        return {completion.name for completion in completions}

    def test_lsp_namespace(self) -> None:
        completions = self.complete(
            "from typing import TYPE_CHECKING\n"
            "if TYPE_CHECKING:\n"
            "    import lsp_typing as Lsp\n"
            "else:\n"
            "    from gi.repository import Lsp\n"
            "Lsp."
        )
        self.assertIn("Server", completions)
        self.assertIn("Position", completions)
        self.assertIn("CompletionItem", completions)

    def test_lsp_instance(self) -> None:
        completions = self.complete(
            "from typing import TYPE_CHECKING\n"
            "if TYPE_CHECKING:\n"
            "    import lsp_typing as Lsp\n"
            "else:\n"
            "    from gi.repository import Lsp\n"
            "caps = Lsp.ServerCaps.new()\n"
            "caps."
        )
        self.assertIn("get_completion", completions)
        self.assertIn("set_text_document_sync", completions)
        self.assertIn("to_variant", completions)

    def test_test_namespace(self) -> None:
        completions = self.complete(
            "from typing import TYPE_CHECKING\n"
            "if TYPE_CHECKING:\n"
            "    import lsp_test_typing as LspTest\n"
            "else:\n"
            "    from gi.repository import LspTest\n"
            "LspTest."
        )
        self.assertIn("create_stream_pair", completions)


if __name__ == "__main__":
    unittest.main()
