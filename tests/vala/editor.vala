using Lsp;

/*
 * Exercise Editor in both protocol directions. Its document API drives the
 * Server mock, then the Server's typed Client drives Editor signals and
 * request overrides.
 */

private Uri parse_uri (string value) {
    try {
        return Uri.parse (value, UriFlags.NONE);
    } catch (UriError e) {
        error ("failed to parse test URI: %s", e.message);
    }
}

private async void defer_once () {
    Timeout.add (1, defer_once.callback);
    yield;
}

private async void wait_for_server_events (
    TestServer server,
    int expected_count
) {
    while (server.event_count < expected_count)
        yield defer_once ();
}

private async void wait_for_editor_events (
    TestEditor editor,
    int expected_count
) {
    while (editor.event_count < expected_count)
        yield defer_once ();
}

private async void run_editor (
    TestEditor editor,
    TestServer server,
    MainLoop loop
) {
    try {
        var workspace = new WorkspaceFolder (
            parse_uri ("file:///workspace"),
            "workspace");
        var uri = parse_uri ("file:///server-test.vala");

        yield editor.initialize_async (workspace);
        yield wait_for_server_events (server, 2);
        assert (editor.init_result != null);
        assert (server.initialize_locale == null);
        assert (server.initialize_root_uri == "file:///workspace");
        assert (server.initialize_workspace_count == 1);

        yield editor.initialized_async ();
        yield wait_for_server_events (server, 4);

        yield editor.open_text_document_async (
            uri,
            LanguageId.VALA,
            "class Before {}");
        // Notification completion only confirms the send, not peer dispatch.
        yield wait_for_server_events (server, 6);
        assert (editor.text_documents.contains (uri));
        assert (server.opened_uri == "file:///server-test.vala");
        assert (server.opened_language_id == LanguageId.VALA);
        assert (server.opened_version == 1);
        assert (server.opened_text == "class Before {}");

        TextDocumentContentChangeEvent[] changes = {
            TextDocumentContentChangeEvent (
                null,
                "class After {}")
        };
        yield editor.edit_text_document_async (uri, 2, changes);
        yield wait_for_server_events (server, 8);
        assert (server.changed_uri == "file:///server-test.vala");
        assert (server.changed_version == 2);
        assert (server.changed_content_count == 1);
        assert (server.changed_text == "class After {}");

        yield editor.close_text_document_async (uri);
        yield wait_for_server_events (server, 10);
        assert (!editor.text_documents.contains (uri));
        assert (server.closed_uri == "file:///server-test.vala");

        var protocol_client = (!) server.peer_client;

        yield protocol_client.show_message_async (
            MessageType.INFO,
            "Build completed");
        yield wait_for_editor_events (editor, 1);
        assert (editor.shown_type == MessageType.INFO);
        assert (editor.shown_message == "Build completed");

        yield protocol_client.log_message_async (
            MessageType.LOG,
            "Index refreshed");
        yield wait_for_editor_events (editor, 2);
        assert (editor.logged_type == MessageType.LOG);
        assert (editor.logged_message == "Index refreshed");

        yield protocol_client.log_trace_async (
            "request complete",
            "elapsed=2ms");
        yield wait_for_editor_events (editor, 3);
        assert (editor.trace_message == "request complete");
        assert (editor.trace_verbose == "elapsed=2ms");

        Diagnostic[] diagnostics = {
            new Diagnostic (
                "unused value",
                Range (Position (1, 2), Position (1, 7))) {
                severity = DiagnosticSeverity.WARNING
            }
        };
        yield protocol_client.publish_diagnostics_async (
            uri,
            diagnostics,
            2);
        yield wait_for_editor_events (editor, 4);
        assert (editor.diagnostic_uri == "file:///server-test.vala");
        assert (editor.diagnostic_version == 2);
        assert (editor.diagnostic_count == 1);
        assert (editor.diagnostic_message == "unused value");

        MessageActionItem[] actions = {
            MessageActionItem ("Apply"),
            MessageActionItem ("Cancel")
        };
        var selected = yield protocol_client.ask_message_async (
            MessageType.WARNING,
            "Apply suggested edit?",
            actions);
        assert (selected != null);
        assert (((MessageActionItem) selected).title == "Apply");
        assert (editor.prompt_type == MessageType.WARNING);
        assert (editor.prompt_message == "Apply suggested edit?");
        assert (editor.prompt_action_count == 2);
        assert (editor.prompt_first_action == "Apply");

        var selection = Range (
            Position (4, 1),
            Position (4, 5));
        var shown = yield protocol_client.show_document_async (
            uri,
            true,
            true,
            selection);
        assert (shown);
        assert (editor.shown_document_uri == "file:///server-test.vala");
        assert (editor.shown_document_external);
        assert (editor.shown_document_take_focus);
        assert (editor.shown_document_selection != null);
        assert (editor.shown_document_selection.start.line == 4);
        assert (editor.shown_document_selection.end.character == 5);

        var edit = new WorkspaceEdit.from_variant (
            new VariantDict ().end ());
        var apply_result = yield protocol_client.apply_edit_async (
            edit,
            "Apply generated edit");
        assert (apply_result.applied);
        assert (editor.applied_edit_label == "Apply generated edit");

        string[] expected_server_events = {
            "initialize",
            "initialize-finish",
            "initialized",
            "initialized-finish",
            "did-open",
            "did-open-finish",
            "did-change",
            "did-change-finish",
            "did-close",
            "did-close-finish"
        };
        assert (server.event_count == expected_server_events.length);
        for (var i = 0; i < expected_server_events.length; i++)
            assert (server.event_at (i) == expected_server_events[i]);

        string[] expected_editor_events = {
            "show-message",
            "log-message",
            "log-trace",
            "publish-diagnostics",
            "show-message-request",
            "show-document",
            "apply-edit"
        };
        assert (editor.event_count == expected_editor_events.length);
        for (var i = 0; i < expected_editor_events.length; i++)
            assert (editor.event_at (i) == expected_editor_events[i]);
    } catch (Error e) {
        error ("Vala Editor/Server test failed: %s", e.message);
    }

    loop.quit ();
}

private int main (string[] args) {
    IOStream server_stream;
    IOStream editor_stream;
    create_test_stream_pair (out server_stream, out editor_stream);

    var loop = new MainLoop ();
    var server = new TestServer (loop);
    var editor = new TestEditor ();
    server.accept_io_stream (server_stream);
    editor.accept_io_stream (editor_stream);
    run_editor.begin (editor, server, loop);

    bool timed_out = false;
    uint timeout_id = Timeout.add_seconds (5, () => {
        timed_out = true;
        loop.quit ();
        return Source.REMOVE;
    });
    loop.run ();
    if (!timed_out)
        Source.remove (timeout_id);

    assert (!timed_out);
    return 0;
}
