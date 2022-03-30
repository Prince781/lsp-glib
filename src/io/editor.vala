/* client.vala
 *
 * Copyright 2021 Princeton Ferro <princetonferro@gmail.com>
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
public abstract class Lsp.Editor : Jsonrpc.Server {
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

    protected Editor () {
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
}
