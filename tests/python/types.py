"""Exercise larger typed payloads through the generated PyGObject API.

These tests use the same GVariant serialization boundary exposed by lsp-glib.
The Editor/Server suites separately cover JSON-RPC framing and dispatch.
"""

# PyGObject namespaces are generated at runtime and do not provide .pyi files.
# pyright: reportMissingImports=false
# pyright: reportArgumentType=false, reportOptionalMemberAccess=false
# pyright: reportOptionalSubscript=false

import unittest
from typing import TYPE_CHECKING, Any

import gi

gi.require_version("Lsp", "3.0")

from gi.repository import GLib  # pyright: ignore[reportAttributeAccessIssue]

if TYPE_CHECKING:
    import lsp_typing as Lsp
else:
    from gi.repository import Lsp  # pyright: ignore[reportAttributeAccessIssue]


def make_range(
    start_line: int,
    start_character: int,
    end_line: int,
    end_character: int,
) -> Any:
    start = Lsp.Position()
    start.init(start_line, start_character)
    end = Lsp.Position()
    end.init(end_line, end_character)
    result = Lsp.Range()
    result.init(start, end)
    return result


class TypedSerializationTest(unittest.TestCase):
    def test_completion_list(self) -> None:
        edit = Lsp.TextEdit()
        edit.init(make_range(3, 4, 3, 9), "print(${1:value})", None)

        item = Lsp.CompletionItem.new(
            "print",
            Lsp.CompletionItemKind.FUNCTION,
        )
        label_details = Lsp.CompletionItemLabelDetails.new(
            "(value)",
            "GLib",
        )
        documentation = Lsp.MarkupContent.new(
            Lsp.MarkupKind.MARKDOWN,
            "**Print** a value.",
        )
        item.set_label_details(label_details)
        item.set_tags(Lsp.CompletionItemTag.DEPRECATED)
        item.set_documentation(documentation)
        item.set_commit_chars([";", "("])
        item.set_insert_text_format(Lsp.InsertTextFormat.SNIPPET)
        item.set_text_edit(edit)
        item.set_data(GLib.Variant("s", "completion-token"))

        decoded = Lsp.CompletionList.from_variant(
            Lsp.CompletionList.new(True, [item]).to_variant()
        )

        self.assertTrue(decoded.get_is_incomplete())
        decoded_items = decoded.get_items()
        self.assertEqual(len(decoded_items), 1)
        self.assertEqual(decoded_items[0].get_label(), "print")
        self.assertEqual(
            decoded_items[0].get_insert_text_format(),
            Lsp.InsertTextFormat.SNIPPET,
        )
        self.assertEqual(
            decoded_items[0].get_text_edit().get_new_text(),
            "print(${1:value})",
        )
        self.assertEqual(decoded_items[0].get_data().unpack(), "completion-token")

    def test_initialization(self) -> None:
        root_uri = GLib.Uri.parse(
            "file:///workspace",
            GLib.UriFlags.NONE,
        )
        capabilities = Lsp.ServerCaps.new()
        completion = Lsp.CompletionOptions.new(True, [".", ":"])
        inlay_hint = Lsp.InlayHintOptions.new(True)
        capabilities.set_text_document_sync(
            Lsp.TextDocumentSyncKind.INCREMENTAL
        )
        capabilities.set_completion(completion)
        capabilities.set_hover(True)
        capabilities.set_inlay_hint(inlay_hint)

        # Nullable integer properties are exposed as pointers by GI, so
        # PyGObject cannot safely marshal a non-null processId here.
        params = Lsp.InitializeParams.new()
        client_info = Lsp.ClientInfo.new("Test Editor", "1.2.3")
        workspace = Lsp.WorkspaceFolder.new(root_uri, "workspace")
        params.set_client_info(client_info)
        params.set_locale("en-US")
        params.set_root_uri(root_uri)
        params.set_trace(Lsp.TraceValue.MESSAGES)
        params.set_workspaces([workspace])
        params.set_initialization_options(
            GLib.Variant("s", "initialization-token")
        )

        decoded_params = Lsp.InitializeParams.from_variant(params.to_variant())
        self.assertEqual(decoded_params.get_client_info().get_name(), "Test Editor")
        self.assertEqual(decoded_params.get_locale(), "en-US")
        self.assertEqual(decoded_params.get_trace(), Lsp.TraceValue.MESSAGES)
        self.assertEqual(len(decoded_params.get_workspaces()), 1)
        self.assertEqual(
            decoded_params.get_initialization_options().unpack(),
            "initialization-token",
        )

        result = Lsp.InitializeResult.new(capabilities)
        server_info = Lsp.ServerInfo.new("VLS", "3.18.0")
        result.set_server_info(server_info)
        decoded_result = Lsp.InitializeResult.from_variant(result.to_variant())
        decoded_caps = decoded_result.get_capabilities()
        self.assertEqual(
            decoded_caps.get_text_document_sync(),
            Lsp.TextDocumentSyncKind.INCREMENTAL,
        )
        self.assertTrue(decoded_caps.get_completion().get_supports_resolve())
        self.assertTrue(decoded_caps.get_hover())
        self.assertTrue(decoded_caps.get_inlay_hint().get_resolve_provider())

    def test_workspace_edit(self) -> None:
        uri = GLib.Uri.parse(
            "file:///workspace/generated.vala",
            GLib.UriFlags.NONE,
        )
        create = Lsp.CreateFile.new()
        create.set_uri(uri)
        create.set_options(Lsp.CreateFileOptions.OVERWRITE)
        create.set_annotation_id("create-file")

        edit = Lsp.WorkspaceEdit.new()
        edit.add_document_change(create)
        annotation = Lsp.ChangeAnnotation.new(
            "Create generated source",
            True,
            "The file is generated by the compiler.",
        )
        edit.set_change_annotation(
            "create-file",
            annotation,
        )

        decoded = Lsp.WorkspaceEdit.from_variant(edit.to_variant())
        changes = decoded.get_document_changes()
        self.assertEqual(len(changes), 1)
        self.assertIsInstance(changes[0], Lsp.CreateFile)
        self.assertEqual(changes[0].get_uri().to_string(), uri.to_string())
        self.assertEqual(
            changes[0].get_options(),
            Lsp.CreateFileOptions.OVERWRITE,
        )
        annotations = decoded.get_change_annotations()
        self.assertEqual(
            annotations["create-file"].get_label(),
            "Create generated source",
        )
        self.assertTrue(
            annotations["create-file"].get_needs_confirmation()
        )

    def test_typed_protocol_unions(self) -> None:
        position = Lsp.Position()
        position.init(2, 9)
        part = Lsp.InlayHintLabelPart.new(": string")
        tooltip = Lsp.MarkupContent.new(
            Lsp.MarkupKind.MARKDOWN,
            "Inferred **type**",
        )
        part.set_tooltip(tooltip)

        hint = Lsp.InlayHint.new(
            position,
            "temporary",
            Lsp.InlayHintKind.TYPE,
        )
        hint.set_label_parts([part])
        hint.set_padding(
            Lsp.InlayHintPadding.LEFT | Lsp.InlayHintPadding.RIGHT
        )

        decoded_hint = Lsp.InlayHint.from_variant(hint.to_variant())
        self.assertIsNone(decoded_hint.get_label())
        self.assertEqual(decoded_hint.get_label_parts()[0].get_value(), ": string")

        uri = GLib.Uri.parse(
            "file:///workspace/main.vala",
            GLib.UriFlags.NONE,
        )
        symbol = Lsp.WorkspaceSymbol.new(
            "Example",
            Lsp.SymbolKind.CLASS,
            uri,
            make_range(0, 0, 6, 1),
            "demo",
            Lsp.SymbolTag.DEPRECATED,
        )
        decoded_symbol = Lsp.WorkspaceSymbol.from_variant(symbol.to_variant())
        self.assertEqual(decoded_symbol.get_uri().to_string(), uri.to_string())
        self.assertEqual(decoded_symbol.get_range().end.line, 6)
        self.assertEqual(decoded_symbol.get_tags(), Lsp.SymbolTag.DEPRECATED)


if __name__ == "__main__":
    unittest.main()
