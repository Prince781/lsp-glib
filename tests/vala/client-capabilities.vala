using Lsp;

/*
 * Client capability tests cover the full nested hierarchy sent in
 * InitializeParams: workspace edits, text synchronization, and completion.
 * Array-valued fields are populated so both their element encodings and the
 * containing capability objects are exercised.
 */

private void test_client_capabilities_round_trip () {
    try {
        var workspace_edit = new WorkspaceEditClientCaps () {
            document_changes = true,
            resource_ops = {
                ResourceOperationKind.CREATE.to_string (),
                ResourceOperationKind.RENAME.to_string (),
                ResourceOperationKind.DELETE.to_string ()
            },
            failure_handling = FailureHandlingKind.TRANSACTIONAL,
            normalizes_line_endings = true,
            change_annotations = true,
            change_annotations_group_on_label = true
        };
        var completion = new CompletionClientCaps () {
            snippets = true,
            commit_chars = true,
            documentation_formats = {
                MarkupKind.MARKDOWN,
                MarkupKind.PLAINTEXT
            },
            deprecated_property = true,
            preselect_property = true,
            supported_tags = CompletionItemTag.DEPRECATED,
            insert_replace = true,
            resolve_properties = { "documentation", "detail" },
            insert_text_modes = {
                InsertTextMode.AS_IS,
                InsertTextMode.ADJUST_INDENTATION
            },
            item_kinds = {
                CompletionItemKind.TEXT,
                CompletionItemKind.FUNCTION,
                CompletionItemKind.TYPE_PARAMETER
            },
            context = true,
            label_details = true
        };
        var original = new ClientCaps () {
            workspace = new WorkspaceClientCaps () {
                apply_edit = true,
                workspace_edit = workspace_edit
            },
            text_document = new TextDocumentClientCaps () {
                synchronization =
                    TextDocumentSyncClientCaps.WILL_SAVE |
                    TextDocumentSyncClientCaps.WILL_SAVE_WAIT_UNTIL |
                    TextDocumentSyncClientCaps.DID_SAVE,
                completion = completion
            }
        };

        var decoded = new ClientCaps.from_variant (
            original.to_variant ());
        assert (decoded.workspace != null);
        assert (decoded.workspace.apply_edit);
        assert (decoded.workspace.workspace_edit != null);
        var decoded_edit = decoded.workspace.workspace_edit;
        assert (decoded_edit.document_changes);
        assert (decoded_edit.resource_ops != null);
        assert (decoded_edit.resource_ops.length == 3);
        assert (
            decoded_edit.failure_handling ==
            FailureHandlingKind.TRANSACTIONAL);
        assert (decoded_edit.normalizes_line_endings);
        assert (decoded_edit.change_annotations);
        assert (decoded_edit.change_annotations_group_on_label);

        assert (decoded.text_document != null);
        assert (
            TextDocumentSyncClientCaps.WILL_SAVE in
            decoded.text_document.synchronization);
        assert (
            TextDocumentSyncClientCaps.WILL_SAVE_WAIT_UNTIL in
            decoded.text_document.synchronization);
        assert (
            TextDocumentSyncClientCaps.DID_SAVE in
            decoded.text_document.synchronization);
        assert (decoded.text_document.completion != null);
        var decoded_completion = decoded.text_document.completion;
        assert (decoded_completion.snippets);
        assert (decoded_completion.commit_chars);
        assert (decoded_completion.documentation_formats != null);
        assert (decoded_completion.documentation_formats.length == 2);
        assert (
            decoded_completion.documentation_formats[0] ==
            MarkupKind.MARKDOWN);
        assert (decoded_completion.deprecated_property);
        assert (decoded_completion.preselect_property);
        assert (
            CompletionItemTag.DEPRECATED in
            decoded_completion.supported_tags);
        assert (decoded_completion.insert_replace);
        assert (decoded_completion.resolve_properties != null);
        assert (decoded_completion.resolve_properties.length == 2);
        assert (decoded_completion.insert_text_modes != null);
        assert (decoded_completion.insert_text_modes.length == 2);
        assert (
            decoded_completion.insert_text_modes[1] ==
            InsertTextMode.ADJUST_INDENTATION);
        assert (decoded_completion.item_kinds != null);
        assert (decoded_completion.item_kinds.length == 3);
        assert (
            decoded_completion.item_kinds[2] ==
            CompletionItemKind.TYPE_PARAMETER);
        assert (decoded_completion.context);
        assert (decoded_completion.label_details);
    } catch (DeserializeError e) {
        error ("client capabilities round trip failed: %s", e.message);
    }
}

private void test_failure_handling_default () {
    try {
        var unset = new WorkspaceEditClientCaps ();
        assert (
            unset.to_variant ().lookup_value (
                "failureHandling",
                VariantType.STRING) == null);

        var abort = new WorkspaceEditClientCaps () {
            failure_handling = FailureHandlingKind.ABORT
        };
        var encoded = abort.to_variant ();
        var value = encoded.lookup_value (
            "failureHandling",
            VariantType.STRING);
        assert (value != null);
        assert ((string) value == "abort");

        var decoded = new WorkspaceEditClientCaps.from_variant (encoded);
        assert (decoded.failure_handling == FailureHandlingKind.ABORT);
    } catch (DeserializeError e) {
        error ("failure handling round trip failed: %s", e.message);
    }
}

private int main (string[] args) {
    Test.init (ref args);
    Test.add_func (
        "/serialization/client-capabilities/full",
        test_client_capabilities_round_trip);
    Test.add_func (
        "/serialization/client-capabilities/failure-handling-default",
        test_failure_handling_default);
    return Test.run ();
}
