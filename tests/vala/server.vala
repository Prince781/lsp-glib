using Lsp;

/*
 * Drive every basic Server lifecycle and document override through a stock
 * Lsp.Editor. Assertions inspect only values decoded on the Server side.
 */

private Uri parse_uri (string value) {
    try {
        return Uri.parse (value, UriFlags.NONE);
    } catch (UriError e) {
        error ("failed to parse test URI: %s", e.message);
    }
}

private async void wait_for_events (
    TestServer server,
    int expected_count
) {
    while (server.event_count < expected_count) {
        Timeout.add (1, wait_for_events.callback);
        yield;
    }
}

private async void run_protocol (
    Editor editor,
    TestServer server,
    MainLoop loop
) {
    try {
        var workspace = new WorkspaceFolder (
            parse_uri ("file:///workspace"),
            "workspace");
        var init_params = new InitializeParams.with_workspace_folders (
            workspace);
        init_params.locale = "en-US";

        yield editor.initialize_with_params_async (init_params);
        yield wait_for_events (server, 2);
        assert (server.initialize_locale == "en-US");
        assert (server.initialize_root_uri == "file:///workspace");
        assert (server.initialize_workspace_count == 1);

        yield editor.initialized_async ();
        yield wait_for_events (server, 4);

        var uri = parse_uri ("file:///server-test.vala");
        yield editor.open_text_document_async (
            uri,
            LanguageId.VALA,
            "class Before {}");
        yield wait_for_events (server, 6);

        TextDocumentContentChangeEvent[] changes = {
            TextDocumentContentChangeEvent (
                null,
                "class After {}")
        };
        yield editor.edit_text_document_async (uri, 2, changes);
        yield wait_for_events (server, 8);

        yield editor.save_text_document_async (
            uri,
            "class Saved {}");
        yield wait_for_events (server, 10);

        yield editor.close_text_document_async (uri);
        yield wait_for_events (server, 12);

        yield editor.shutdown_async ();
        yield wait_for_events (server, 14);
        assert (editor.is_shutting_down);

        yield editor.exit_async ();
        yield wait_for_events (server, 15);
        assert (editor.exited);

        string[] expected_events = {
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
            "exit"
        };
        assert (server.event_count == expected_events.length);
        for (var i = 0; i < expected_events.length; i++)
            assert (server.event_at (i) == expected_events[i]);

        assert (server.opened_uri == "file:///server-test.vala");
        assert (server.opened_language_id == LanguageId.VALA);
        assert (server.opened_version == 1);
        assert (server.opened_text == "class Before {}");
        assert (server.changed_uri == "file:///server-test.vala");
        assert (server.changed_version == 2);
        assert (server.changed_content_count == 1);
        assert (server.changed_text == "class After {}");
        assert (server.saved_uri == "file:///server-test.vala");
        assert (server.saved_text == "class Saved {}");
        assert (server.closed_uri == "file:///server-test.vala");
    } catch (Error e) {
        error ("Vala Server/Editor protocol test failed: %s", e.message);
    }

    loop.quit ();
}

private int main (string[] args) {
    IOStream server_stream;
    IOStream editor_stream;
    create_test_stream_pair (out server_stream, out editor_stream);

    var loop = new MainLoop ();
    var server = new TestServer (loop);
    var editor = new Editor ();
    server.accept_io_stream (server_stream);
    editor.accept_io_stream (editor_stream);
    run_protocol.begin (editor, server, loop);

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
