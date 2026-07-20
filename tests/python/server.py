"""Drive Python Lsp.Server overrides through a stock Lsp.Editor.

The portable test stream carries real framed JSON-RPC messages. This verifies
both PyGObject's async virtual-method plumbing and the typed LSP codecs used by
the Editor and Server.
"""

# PyGObject namespaces are generated at runtime and do not provide .pyi files.
# pyright: reportMissingImports=false
# pyright: reportArgumentType=false, reportIncompatibleMethodOverride=false

import time
import unittest
from collections.abc import Callable
from typing import TYPE_CHECKING, Any

import gi

gi.require_version("Lsp", "3.0")
gi.require_version("LspTest", "1.0")

from gi.repository import Gio, GLib  # pyright: ignore[reportAttributeAccessIssue]

if TYPE_CHECKING:
    import lsp_test_typing as LspTest
    import lsp_typing as Lsp
else:
    from gi.repository import Lsp, LspTest  # pyright: ignore[reportAttributeAccessIssue]


class BindingServer(Lsp.Server):
    def __init__(self) -> None:
        super().__init__()
        self.events: list[str] = []
        self.initialize_params: Any = None
        self.opened_document: Any = None
        self.changed_document: Any = None
        self.content_changes: list[Any] = []
        self.saved_document: Any = None
        self.saved_text: str | None = None
        self.closed_document: Any = None
        self.fail_initialization = False

    def _complete_task(
        self,
        task: Any,
        callback: Any,
        error_message: str | None,
    ) -> bool:
        if error_message is None:
            task.return_boolean(True)
        else:
            task.return_new_error_literal(
                Gio.io_error_quark(),
                Gio.IOErrorEnum.FAILED,
                error_message,
            )
        callback(self, task)
        return GLib.SOURCE_REMOVE

    def _start_task(
        self,
        client: Any,
        callback: Any,
        error_message: str | None = None,
    ) -> None:
        task = Gio.Task.new(
            self,
            client.get_cancellable(),
            None,
            None,
        )
        GLib.idle_add(
            self._complete_task,
            task,
            callback,
            error_message,
        )

    def do_initialize_async(
        self,
        client: Any,
        init_params: Any,
        callback: Any,
    ) -> None:
        self.events.append("initialize")
        self.initialize_params = init_params
        self._start_task(
            client,
            callback,
            "initialization failed for test"
            if self.fail_initialization
            else None,
        )

    def do_initialize_finish(self, result: Any) -> Any:
        result.propagate_boolean()
        self.events.append("initialize-finish")
        return Lsp.InitializeResult.new(Lsp.ServerCaps.new())

    def do_initialized_async(
        self,
        client: Any,
        callback: Any,
    ) -> None:
        self.events.append("initialized")
        self._start_task(client, callback)

    def do_initialized_finish(self, result: Any) -> None:
        result.propagate_boolean()
        self.events.append("initialized-finish")

    def do_text_document_did_open_async(
        self,
        client: Any,
        text_document: Any,
        callback: Any,
    ) -> None:
        self.events.append("did-open")
        self.opened_document = text_document
        self._start_task(client, callback)

    def do_text_document_did_open_finish(self, result: Any) -> None:
        result.propagate_boolean()
        self.events.append("did-open-finish")

    def do_text_document_did_change_async(
        self,
        client: Any,
        text_document: Any,
        content_changes: list[Any],
        content_changes_length: int,
        callback: Any,
    ) -> None:
        if content_changes_length != len(content_changes):
            raise AssertionError("content change array length does not match")
        self.events.append("did-change")
        self.changed_document = text_document
        self.content_changes = content_changes
        self._start_task(client, callback)

    def do_text_document_did_change_finish(self, result: Any) -> None:
        result.propagate_boolean()
        self.events.append("did-change-finish")

    def do_text_document_did_save_async(
        self,
        client: Any,
        text_document: Any,
        text: str | None,
        callback: Any,
    ) -> None:
        self.events.append("did-save")
        self.saved_document = text_document
        self.saved_text = text
        self._start_task(client, callback)

    def do_text_document_did_save_finish(self, result: Any) -> None:
        result.propagate_boolean()
        self.events.append("did-save-finish")

    def do_text_document_did_close_async(
        self,
        client: Any,
        text_document: Any,
        callback: Any,
    ) -> None:
        self.events.append("did-close")
        self.closed_document = text_document
        self._start_task(client, callback)

    def do_text_document_did_close_finish(self, result: Any) -> None:
        result.propagate_boolean()
        self.events.append("did-close-finish")

    def do_shutdown_async(
        self,
        client: Any,
        callback: Any,
    ) -> None:
        self.events.append("shutdown")
        self._start_task(client, callback)

    def do_shutdown_finish(self, result: Any) -> None:
        result.propagate_boolean()
        self.events.append("shutdown-finish")

    def do_exit(self) -> None:
        self.events.append("exit")


def spin_until(predicate: Callable[[], bool]) -> None:
    context = GLib.MainContext.default()
    deadline = time.monotonic() + 5

    while not predicate():
        if context.pending():
            context.iteration(False)
        elif time.monotonic() < deadline:
            time.sleep(0.001)
        else:
            raise TimeoutError("asynchronous protocol operation did not finish")


def run_async(
    start: Callable[[Callable[..., None]], None],
    finish: Callable[[Any], Any],
) -> Any:
    completed: list[Any] = []
    errors: list[BaseException] = []

    def on_ready(_source: Any, result: Any, *_user_data: Any) -> None:
        try:
            completed.append(finish(result))
        except BaseException as error:
            errors.append(error)

    start(on_ready)
    if completed or errors:
        raise AssertionError("protocol method completed synchronously")
    spin_until(lambda: bool(completed or errors))
    if errors:
        raise errors[0]
    return completed[0]


class ServerTest(unittest.TestCase):
    def test_async_overrides_directly(self) -> None:
        """Keep coverage for Python begin/finish virtual overrides.

        Python-originated calls retain their callback closure, unlike a native
        caller entering the same override through JSON-RPC.
        """

        server = BindingServer()
        server.fail_initialization = True
        client = Lsp.Client()
        uri = GLib.Uri.parse(
            "file:///binding-test.vala",
            GLib.UriFlags.NONE,
        )

        init_params = Lsp.InitializeParams.new()
        init_params.set_locale("en-US")
        with self.assertRaisesRegex(
            GLib.Error,
            "initialization failed for test",
        ):
            run_async(
                lambda callback: server.initialize_async(
                    client,
                    init_params,
                    callback,
                ),
                server.initialize_finish,
            )

        run_async(
            lambda callback: server.initialized_async(client, callback),
            server.initialized_finish,
        )

        opened = Lsp.TextDocumentItem.new(
            uri,
            Lsp.LanguageId.VALA,
            1,
            "class Before {}",
        )
        run_async(
            lambda callback: server.text_document_did_open_async(
                client,
                opened,
                callback,
            ),
            server.text_document_did_open_finish,
        )

        identifier = Lsp.TextDocumentIdentifier()
        identifier.init(uri, 2)
        change = Lsp.TextDocumentContentChangeEvent()
        change.init(None, "class After {}")
        run_async(
            lambda callback: server.text_document_did_change_async(
                client,
                identifier,
                [change],
                callback,
            ),
            server.text_document_did_change_finish,
        )
        run_async(
            lambda callback: server.text_document_did_save_async(
                client,
                identifier,
                "class Saved {}",
                callback,
            ),
            server.text_document_did_save_finish,
        )
        run_async(
            lambda callback: server.text_document_did_close_async(
                client,
                identifier,
                callback,
            ),
            server.text_document_did_close_finish,
        )
        run_async(
            lambda callback: server.shutdown_async(client, callback),
            server.shutdown_finish,
        )
        server.exit()

        self.assertEqual(server.initialize_params.get_locale(), "en-US")
        self.assertEqual(server.opened_document.get_text(), "class Before {}")
        changed_version = server.changed_document.to_variant().lookup_value(
            "version",
            GLib.VariantType.new("x"),
        )
        self.assertIsNotNone(changed_version)
        self.assertEqual(changed_version.get_int64(), 2)
        self.assertEqual(server.content_changes[0].get_text(), "class After {}")
        self.assertEqual(server.saved_text, "class Saved {}")
        self.assertEqual(
            server.closed_document.get_uri().to_string(),
            uri.to_string(),
        )
        self.assertEqual(
            server.events,
            [
                "initialize",
                "initialized",
                "initialized-finish",
                "did-open",
                "did-open-finish",
                "did-change",
                "did-change-finish",
                "did-save",
                "did-save-finish",
                "did-close",
                "did-close-finish",
                "shutdown",
                "shutdown-finish",
                "exit",
            ],
        )

    @unittest.skip(
        "PyGObject drops valac async-vfunc callback state for native callers"
    )
    def test_editor_drives_python_server(self) -> None:
        server_stream, editor_stream = LspTest.create_stream_pair()
        server = BindingServer()
        editor = Lsp.Editor.new()
        server.accept_io_stream(server_stream)
        editor.accept_io_stream(editor_stream)

        workspace_uri = GLib.Uri.parse(
            "file:///workspace",
            GLib.UriFlags.NONE,
        )
        workspace = Lsp.WorkspaceFolder.new(workspace_uri, "workspace")
        init_params = Lsp.InitializeParams.new()
        init_params.set_locale("en-US")
        init_params.set_root_uri(workspace_uri)
        init_params.set_workspaces([workspace])

        run_async(
            lambda callback: editor.initialize_with_params_async(
                init_params,
                callback,
            ),
            editor.initialize_with_params_finish,
        )
        self.assertEqual(server.initialize_params.get_locale(), "en-US")
        self.assertEqual(
            server.initialize_params.get_root_uri().to_string(),
            workspace_uri.to_string(),
        )
        self.assertEqual(len(server.initialize_params.get_workspaces()), 1)

        run_async(
            lambda callback: editor.initialized_async(callback),
            editor.initialized_finish,
        )
        spin_until(lambda: len(server.events) >= 4)

        uri = GLib.Uri.parse(
            "file:///server-test.vala",
            GLib.UriFlags.NONE,
        )
        run_async(
            lambda callback: editor.open_text_document_async(
                uri,
                Lsp.LanguageId.VALA,
                "class Before {}",
                callback,
            ),
            editor.open_text_document_finish,
        )
        spin_until(lambda: len(server.events) >= 6)

        change = Lsp.TextDocumentContentChangeEvent()
        change.init(None, "class After {}")
        run_async(
            lambda callback: editor.edit_text_document_async(
                uri,
                2,
                [change],
                callback,
            ),
            editor.edit_text_document_finish,
        )
        spin_until(lambda: len(server.events) >= 8)

        run_async(
            lambda callback: editor.save_text_document_async(
                uri,
                "class Saved {}",
                callback,
            ),
            editor.save_text_document_finish,
        )
        spin_until(lambda: len(server.events) >= 10)

        run_async(
            lambda callback: editor.close_text_document_async(uri, callback),
            editor.close_text_document_finish,
        )
        spin_until(lambda: len(server.events) >= 12)

        run_async(
            lambda callback: editor.shutdown_async(callback),
            editor.shutdown_finish,
        )
        spin_until(lambda: len(server.events) >= 14)
        self.assertTrue(editor.get_is_shutting_down())

        run_async(
            lambda callback: editor.exit_async(callback),
            editor.exit_finish,
        )
        spin_until(lambda: len(server.events) >= 15)
        self.assertTrue(editor.get_exited())

        self.assertEqual(
            server.events,
            [
                "initialize",
                "initialize-finish",
                "initialized",
                "initialized-finish",
                "did-open",
                "did-open-finish",
                "did-change",
                "did-change-finish",
                "did-save",
                "did-save-finish",
                "did-close",
                "did-close-finish",
                "shutdown",
                "shutdown-finish",
                "exit",
            ],
        )
        self.assertEqual(
            server.opened_document.get_uri().to_string(),
            uri.to_string(),
        )
        self.assertEqual(
            server.opened_document.get_language_id(),
            Lsp.LanguageId.VALA,
        )
        self.assertEqual(server.opened_document.get_version(), 1)
        self.assertEqual(server.opened_document.get_text(), "class Before {}")
        self.assertEqual(
            server.changed_document.get_uri().to_string(),
            uri.to_string(),
        )
        self.assertEqual(server.changed_document.get_version(), 2)
        self.assertEqual(len(server.content_changes), 1)
        self.assertEqual(server.content_changes[0].get_text(), "class After {}")
        self.assertEqual(
            server.saved_document.get_uri().to_string(),
            uri.to_string(),
        )
        self.assertEqual(server.saved_text, "class Saved {}")
        self.assertEqual(
            server.closed_document.get_uri().to_string(),
            uri.to_string(),
        )


if __name__ == "__main__":
    unittest.main()
