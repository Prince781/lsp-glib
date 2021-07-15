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
public abstract class Lsp.Editor : Jsonrpc.Server {
    Jsonrpc.Client? client;

    /**
     * Whether we've exited the server.
     */
    bool exited;

    public Cancellable cancellable { get; private set; }

    public InitializeResult? init_result { get; private set; }

    public HashTable<Uri, TextDocumentItem> text_documents { get; private set; }

    protected Editor () {
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
                                        WorkspaceFolder[]? secondary_workspaces = null) throws Error {
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
     * server.
     */
    public async void open (Uri uri, LanguageId language_id) throws Error {
        if (client == null)
            throw new Lsp.ProtocolError.NO_CONNECTION ("not connected to a client");
    }
}
