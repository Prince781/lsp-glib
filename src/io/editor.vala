/* client.vala
 *
 * Copyright 2021-2022 Princeton Ferro <princetonferro@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/**
 * A JSON-RPC server implementing the client side of the Language Server
 * Protocol.
 *
 * This API is intended for GUIs, which is why incoming LSP notifications have
 * synchronous event handlers rather than virtual async methods.
 */
public class Lsp.Editor : Jsonrpc.Server {
    Jsonrpc.Client? client;

    /**
     * Whether we've exited the server.
     */
    bool exited;

    /**
     * The trace configuration, synchronized with the language server.
     */
    public TraceValue trace_value { get; private set; default = OFF; }

    public Cancellable cancellable { get; private set; }

    /**
     * The initialization info we got from the language server.
     */
    public InitializeResult? init_result { get; private set; }

    public HashTable<Uri, TextDocumentItem> text_documents { get; private set; }

    public Editor () {
        this.cancellable = new Cancellable ();
        this.text_documents = new HashTable<Uri, TextDocumentItem> (uri_hash, uri_equal);
        this.handle_call.connect ((client, method, id, parameters) => {
            handle_call_async.begin (client, method, id, parameters);
            return !exited;
        });
    }

    protected override void notification (Jsonrpc.Client client, string method, Variant parameters) {
        if (exited || init_result == null)
            return;

        try {
            switch (method) {
                case "window/logMessage":
                    var sm_type = expect_property (parameters, "type", VariantType.INT64, "LogMessageParams");
                    string message = (string) expect_property (parameters, "message", VariantType.STRING, "LogMessageParams");
                    log_message (MessageType.parse_int ((int)(int64)sm_type), message);
                    break;

                case "window/showMessage":
                    var sm_type = expect_property (parameters, "type", VariantType.INT64, "ShowMessageParams");
                    string message = (string) expect_property (parameters, "message", VariantType.STRING, "ShowMessageParams");
                    show_message (MessageType.parse_int ((int)(int64)sm_type), message);
                    break;

                case "textDocument/publishDiagnostics":
                    var pd_uri = expect_property (parameters, "uri", VariantType.STRING, "PublishDiagnosticsParams");
                    var pd_version = lookup_property (parameters, "version", VariantType.INT64, "PublishDiagnosticsParams");
                    int64? version = pd_version != null ? (int64?)pd_version : null;
                    Diagnostic[] diags = {};
                    foreach (var diag in expect_property (parameters, "diagnostics", VariantType.ARRAY, "PublishDiagnosticsParams"))
                        diags += new Diagnostic.from_variant (diag);
                    publish_diagnostics (Uri.parse ((string)pd_uri, UriFlags.NONE), version, diags);
                    break;

                case "$/logTrace":
                    var message = (string) expect_property (parameters, "message", VariantType.STRING, "LogTraceParams");
                    var lt_verbose = lookup_property (parameters, "verbose", VariantType.STRING, "LogTraceParams");
                    string? verbose = lt_verbose != null ? (string?)lt_verbose : null;
                    log_trace (message, verbose);
                    break;
            }
        } catch (Error e) {
            warning ("handling notification failed - %s", e.message);
        }
    }

    private async void handle_call_async (Jsonrpc.Client client, string method, Variant id, Variant parameters) {
        if (exited)
            return;
    }

    protected override void client_accepted (Jsonrpc.Client client) {
        if (this.client != client)
            init_result = null;         // reset init_result with a new client
        this.client = client;
    }

    protected override void client_closed (Jsonrpc.Client client) {
        this.init_result = null;
        this.client = null;
    }

    /**
     * Emitted when we receive a `window/showMessage` notification
     *
     * @param type    the message type
     * @param message the actual message
     */
    public virtual signal void show_message (MessageType type, string message);

    /**
     * Emitted when we receive a `textDocument/publishDiagnostics` notification
     *
     * @param uri         the URI for which diagnostic information is reported
     * @param version     (optional, since 3.15.0) the version number of the
     *                    document the diagnostics are published for
     * @param diagnostics an array of diagnostic information items
     */
    public virtual signal void publish_diagnostics (Uri uri, int64? version, Diagnostic[] diagnostics);

    /**
     * Emitted when we receive a `$/logTrace` notification
     *
     * @param message the message to be logged
     * @param verbose additional information that can be computed if the trace
     *                configuration is set to `verbose`
     */
    public virtual signal void log_trace (string message, string? verbose);

    /**
     * Emitted when we receive a `window/logMessage` notification
     *
     * @param type    the message type
     * @param message the actual message
     */
    public virtual signal void log_message (MessageType type, string message);

    /**
     * Initializes the server, if we're connected to one.
     * 
     * @see Lsp.Server.initialize_async
     */
    public async void initialize_async (WorkspaceFolder primary_workspace,
                                        (unowned WorkspaceFolder)[]? secondary_workspaces = null) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
        var init_params = new InitializeParams (primary_workspace, secondary_workspaces);

        Variant? return_value;
        yield client.call_async ("initialize", init_params.to_variant (), cancellable, out return_value);
        
        if (return_value == null)
            throw new DeserializeError.INVALID_TYPE ("expected non-null return value from `initialize`");

        init_result = new InitializeResult.from_variant (return_value);
    }

    /**
     * Opens a file, sending the `textDocument/didOpen` message to the language
     * server. If the file is already open, this does nothing.
     *
     * @param text  if non-null, this means that `uri` is associated with an
     *              in-memory buffer `text`
     */
    public async void open_text_document_async (Uri uri, LanguageId language_id, string? text = null) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
        if (init_result == null)
            throw new Lsp.ProtocolError.CLIENT_NOT_INITIALIZED ("client not initialized");

        if (text_documents.contains (uri))
            return;     // the document is already open

        bool in_memory = true;
        if (text == null) {
            var file = File.new_for_uri (uri.to_string ());
            var bytes = yield file.load_bytes_async (cancellable, null);
            text = (string?)bytes.get_data ();  // null means the file was empty
            in_memory = false;
        }

        var text_document = new TextDocumentItem (uri, language_id, 1, text ?? "");
        text_document.state = in_memory ? TextDocumentItem.State.IN_MEMORY : TextDocumentItem.State.UNMODIFIED;

        var parameters = new VariantDict ();
        parameters.insert_value ("textDocument", text_document.to_variant ());

        yield client.send_notification_async ("textDocument/didOpen", parameters.end (), cancellable);

        text_documents[uri] = text_document;
    }

    /**
     * The document change notification is sent from the client to the server
     * to signal changes to a text document. Before a client can change a text
     * document it must claim ownership of its content using the
     * `textDocument/didOpen` notification (see {@link
     * open_text_document_async}). In 2.0 the shape of the params has changed
     * to include proper version numbers.
     *
     * @param uri             the URI of the document that has been modified
     * @param version         the version numebr points to the version after all
     *                        provided content changes have been applied
     * @param content_changes the actual content changes. The content changes describe single state
     *                        changes to the document. So if there are two content changes c1 (at
     *                        array index 0) and c2 (at array index 1) for a document in state S then
     *                        c1 moves the document from S to S2 and c2 from S2 to S3. So c1 is
     *                        computed on the state S and c2 is computed on the state S2.
     *                        To mirror the content of a document using change events use the following
     *                        approach:
     *                        * start with the same initial content
     *                        * apply the 'textDocument/didChange' notifications in the order you
     *                          receive them.
     *                        * apply the `TextDocumentContentChangeEvent`s in a single notification
     *                          in the order you receive them.
     */
    public async void edit_text_document_async (Uri uri, int64 version, (unowned TextDocumentContentChangeEvent)[] content_changes) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
        if (init_result == null)
            throw new Lsp.ProtocolError.CLIENT_NOT_INITIALIZED ("client not initialized");

        if (!text_documents.contains (uri))
            return;     // the document is not open

        var text_document = text_documents[uri];
        if (version <= text_document.version)
            return;     // discard stale changes

        var parameters = new VariantDict ();
        Variant[] content_changes_list = {};
        foreach (var content_change in content_changes) {
            content_changes_list += content_change.to_variant ();
        }
        parameters.insert_value ("textDocument", TextDocumentIdentifier (text_document.uri, version).to_variant ());
        parameters.insert_value ("contentChanges", content_changes_list);

        yield client.send_notification_async ("textDocument/didChange", parameters.end (), cancellable);

        if (version > text_document.version)
            text_document.version = version;
    }

    /**
     * Closes a file, sending the `textDocument/didClose` message to the
     * language server. If the file is not open, this does nothing.
     */
    public async void close_text_document_async (Uri uri) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
        if (init_result == null)
            throw new Lsp.ProtocolError.CLIENT_NOT_INITIALIZED ("client not initialized");

        if (!text_documents.contains (uri))
            return;     // the document is not open

        var text_document = text_documents[uri];
        var parameters = new VariantDict ();
        parameters.insert_value ("textDocument", TextDocumentIdentifier (text_document.uri, text_document.version).to_variant ());

        yield client.send_notification_async ("textDocument/didClose", parameters.end (), cancellable);

        text_documents.remove (uri);
    }

    /**
     * A notification that should be used by the client to modify the trace
     * setting of the server.
     */
    public async void set_trace_async (TraceValue trace_value) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
        if (init_result == null)
            throw new Lsp.ProtocolError.CLIENT_NOT_INITIALIZED ("client not initialized");

        var parameters = new VariantDict ();
        parameters.insert_value ("value", trace_value.to_string ());

        yield client.send_notification_async ("$/setTrace", parameters.end (), cancellable);
        this.trace_value = trace_value;         // synchronize on success
    }

    /**
     * The code action request is sent from the client to the server to compute
     * commands for a given text document and range. These commands are typically code
     * fixes to either fix problems or to beautify/refactor code. The result of a
     * textDocument/codeAction request is an array of Command literals which are
     * typically presented in the user interface. To ensure that a server is useful in
     * many clients the commands specified in a code actions should be handled by the
     * server and not by the client (see workspace/executeCommand and
     * ServerCapabilities.executeCommandProvider). If the client supports providing
     * edits with a code action then that mode should be used.
     *
     * Since version 3.16.0: a client can offer a server to delay the computation of
     * code action properties during a ‘textDocument/codeAction’ request:
     *
     * This is useful for cases where it is expensive to compute the value of a
     * property (for example the edit property). Clients signal this through the
     * codeAction.resolveSupport capability which lists all properties a client can
     * resolve lazily. The server capability codeActionProvider.resolveProvider
     * signals that a server will offer a codeAction/resolve route. To help servers to
     * uniquely identify a code action in the resolve request, a code action literal
     * can optional carry a data property. This is also guarded by an additional
     * client capability codeAction.dataSupport. In general, a client should offer
     * data support if it offers resolve support. It should also be noted that servers
     * shouldn’t alter existing attributes of a code action in a codeAction/resolve
     * request.
     *
     * Since version 3.8.0: support for CodeAction literals to enable the
     * following scenarios:
     *
     *  * the ability to directly return a workspace edit from the code action
     *    request. This avoids having another server roundtrip to execute an actual
     *    code action. However server providers should be aware that if the code
     *    action is expensive to compute or the edits are huge it might still be
     *    beneficial if the result is simply a command and the actual edit is only
     *    computed when needed.
     *  * the ability to group code actions using a kind.
     *    Clients are allowed to ignore that information. However it allows them to
     *    better group code action for example into corresponding menus (e.g. all
     *    refactor code actions into a refactor menu).
     *
     * Clients need to announce their support for code action literals (e.g. literals
     * of type CodeAction) and code action kinds via the corresponding client
     * capability codeAction.codeActionLiteralSupport.
     *
     * @param uri     the URI of the document in which the command was invoked
     * @param range   the range for which the command was invoked
     * @param trigger the reason why this code action request happened, or
     *                {@link CodeActionTriggerKind.UNSET} for no reason
     * @param only    if non-null, limit results to these kinds only
     *
     * @return a list of code actions and commands available at the current
     *         range in the document, or null if there are none
     */
    public async Action[]? code_action_async (Uri uri, Range range,
                                              CodeActionTriggerKind trigger = CodeActionTriggerKind.UNSET,
                                              CodeActionKind[]? only = null) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
        if (init_result == null)
            throw new Lsp.ProtocolError.CLIENT_NOT_INITIALIZED ("client not initialized");

        var parameters = new VariantDict ();
        parameters.insert_value ("textDocument", TextDocumentIdentifier.unversioned (uri).to_variant ());
        parameters.insert_value ("range", range.to_variant ());
        parameters.insert_value ("context", new CodeActionContext () {
            trigger = trigger,
            only = only
        }.to_variant ());

        Variant? return_value;
        yield client.call_async ("textDocument/codeAction", parameters.end (), cancellable, out return_value);

        if (return_value == null)
            return null;

        Action[] actions = {};
        foreach (var item in return_value) {
            if (!item.is_of_type (VariantType.VARDICT))
                throw new DeserializeError.UNEXPECTED_ELEMENT ("value is not a structured element");
            if (item.lookup_value ("kind", null) != null)
                actions += new CodeAction.from_variant (item);
            else if (item.lookup_value ("command", null) != null)
                actions += new Command.from_variant (item);
            else
                throw new DeserializeError.UNEXPECTED_ELEMENT ("value is neither a code action nor a command");
        }
        return actions.length > 0 ? actions : null;
    }
}
