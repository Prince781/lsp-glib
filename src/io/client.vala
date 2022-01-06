/* editor.vala
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
 */
public abstract class Lsp.Client : Jsonrpc.Server {
    Jsonrpc.Client? client;

    /**
     * Whether we've exited the server.
     */
    bool exited;

    public Cancellable cancellable { get; private set; }

    /**
     * The initialization info we got from the language server.
     */
    public InitializeResult? init_result { get; private set; }

    public HashTable<Uri, TextDocumentItem> text_documents { get; private set; }

    protected Client () {
        this.cancellable = new Cancellable ();
        this.text_documents = new HashTable<Uri, TextDocumentItem> (uri_hash, uri_equal);
        this.notification.connect (notification_async);
        this.handle_call.connect ((client, method, id, parameters) => {
            handle_call_async.begin (client, method, id, parameters);
            return !exited;
        });
    }

    private async void notification_async (Jsonrpc.Client client, string method, Variant parameters) {
        if (exited)
            return;
    }

    private async void handle_call_async (Jsonrpc.Client client, string method, Variant id, Variant parameters) {
        if (exited)
            return;
    }

    protected override void client_accepted (Jsonrpc.Client client) {
        if (this.client == null)
            this.client = client;
    }

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
    public async void open_async (Uri uri, LanguageId language_id, string? text = null) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");

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
    public async void close_async (Uri uri) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");

        if (!text_documents.contains (uri))
            return;     // the document is not open

        var text_document = text_documents[uri];
        var parameters = new VariantDict ();
        parameters.insert_value ("textDocument", TextDocumentIdentifier (text_document.uri, text_document.version).to_variant ());

        yield client.send_notification_async ("textDocument/didClose", parameters.end (), cancellable);

        text_documents.remove (uri);
    }
}
