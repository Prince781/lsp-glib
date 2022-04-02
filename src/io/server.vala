/* server.vala
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
 * A JSON-RPC server implementing the server's side of the Language Server
 * Protocol using {@link GLib.MainLoop}.
 */
public abstract class Lsp.Server : Jsonrpc.Server {
    MainLoop loop;

    /**
     * Whether we've received a shutdown request.
     */
    bool is_shutting_down;

    /**
     * Whether we've exited the server.
     */
    bool exited;

    /**
     * How we should log trace messages to the client.
     */
    public TraceValue trace_value { get; private set; default = OFF; }

    public Cancellable cancellable { get; private set; default = new Cancellable (); }

    /**
     * Creates a new server.
     *
     * @param loop  The main loop
     */
    protected Server (MainLoop loop) {
        this.loop = loop;
        this.notification.connect (notification_async);
        this.handle_call.connect ((client, method, id, parameters) => {
            handle_call_async.begin (client, method, id, parameters);
            return !exited;
        });
    }

    private async void notification_async (Jsonrpc.Client client, string method, Variant parameters) {
        if (exited)
            return;

        debug ("got notification - %s", method);
        if (is_shutting_down && method != "exit")
            return;

        var lsp_client = new Client (this, client);
        try {
            switch (method) {
                case "exit":
                    exit ();
                    exited = true;
                    break;

                case "initialized":
                    yield initialized_async (lsp_client);
                    break;

                case "textDocument/didChange":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.VARDICT, "DidChangeTextDocumentParams");
                    var cc_variant = expect_property (parameters, "contentChanges", VariantType.ARRAY, "DidChangeTextDocumentParams");
                    var content_changes = new TextDocumentContentChangeEvent[] {};
                    foreach (var cc in cc_variant) {
                        if (cc == null)
                            throw new DeserializeError.INVALID_TYPE ("expected non-null content changes for DidChangeTextDocumentParams");
                        content_changes += TextDocumentContentChangeEvent.from_variant (cc);
                    }
                    yield text_document_did_change_async (lsp_client, TextDocumentIdentifier.from_variant (tdi_variant), content_changes);
                    break;

                case "textDocument/didClose":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.VARDICT, "DidCloseTextDocumentParams");
                    yield text_document_did_close_async (lsp_client, TextDocumentIdentifier.from_variant (tdi_variant));
                    break;

                case "textDocument/didOpen":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.VARDICT, "DidOpenTextDocumentParams");
                    yield text_document_did_open_async (lsp_client, new TextDocumentItem.from_variant (tdi_variant));
                    break;
                
                case "textDocument/didSave":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.VARDICT, "DidSaveTextDocumentParams");
                    var text_variant = lookup_property (parameters, "text", VariantType.STRING, "DidSaveTextDocumentParams");
                    string? text = text_variant != null ? (string) text_variant : null;
                    yield text_document_did_save_async (lsp_client, TextDocumentIdentifier.from_variant (tdi_variant), text);
                    break;

                case "$/setTrace":
                    var st_value = (string) expect_property (parameters, "value", VariantType.STRING, "SetTraceParams");
                    trace_value = TraceValue.parse_string (st_value);
                    break;

                default:
                    warning ("notification not supported: %s", method);
                    break;
            }
        } catch (Error e) {
            warning ("notification failed - %s", e.message);
        }
    }

    private async void handle_call_async (Jsonrpc.Client client, string method, Variant id, Variant parameters) {
        if (exited)
            return;

        debug ("got call - %s", method);
        try {
            if (is_shutting_down && method != "exit") {
                debug ("rejected because we're already shutting down");
                yield reply_error_async (client, id, Jsonrpc.ClientError.INVALID_REQUEST, "server is shutting down");
                return;
            }

            var lsp_client = new Client (this, client);
            switch (method) {
                case "initialize":
                    var init_params = new InitializeParams.from_variant (parameters);
                    var init_result = yield initialize_async (lsp_client, init_params);
                    yield client.reply_async (id, init_result.to_variant (), cancellable);
                    break;

                case "shutdown":
                    is_shutting_down = true;
                    yield shutdown_async (lsp_client);
                    yield client.reply_async (id, new Variant.maybe (VariantType.VARIANT, null), cancellable);
                    break;

                case "textDocument/codeAction":
                    var text_document = TextDocumentIdentifier.from_variant (expect_property (parameters, "textDocument", VariantType.VARIANT, "CodeActionParams"));
                    var range = Range.from_variant (expect_property (parameters, "range", VariantType.VARIANT, "CodeActionParams"));
                    var context = new CodeActionContext.from_variant (expect_property (parameters, "context", VariantType.VARIANT, "CodeActionParams"));
                    Variant[] actions = {};
                    foreach (var action in yield code_action_async (lsp_client, text_document, range, context))
                        actions += action.to_variant ();
                    yield client.reply_async (id, actions, cancellable);
                    break;

                default:
                    yield reply_error_async (client, id, Jsonrpc.ClientError.METHOD_NOT_FOUND);
                    break;
            }
        } catch (DeserializeError e) {
            warning ("request failed - deserialize params failed - %s", e.message);
            yield reply_error_async (client, id, Jsonrpc.ClientError.INVALID_PARAMS, e.message);
        } catch (ProtocolError.METHOD_NOT_IMPLEMENTED e) {
            yield reply_error_async (client, id, Jsonrpc.ClientError.METHOD_NOT_FOUND, e.message);
        } catch (Error e) {
            yield reply_error_async (client, id, Jsonrpc.ClientError.INTERNAL_ERROR, e.message);
        }
    }

    private async void reply_error_async (Jsonrpc.Client client, Variant id, Jsonrpc.ClientError client_error, string? message = null) {
        try {
            yield client.reply_error_async (id, client_error, message, cancellable);
        } catch (Error e) {
            warning ("failed to reply with error to client - %s", e.message);
        }
    }

    /**
     * The initialize request is sent as the first request from the client
     * to the server.
     * If the server receives a request or notification before the
     * initialize request it should act as follows:
     *
     * For a request the response should be an error with code: `-32002`. The
     * message can be picked by the server.  Notifications should be
     * dropped, except for the exit notification. This will allow the exit
     * of a server without an initialize request.
     *
     * Until the server has responded to the initialize request with an
     * InitializeResult, the client must not send any additional requests
     * or notifications to the server. In addition the server is not
     * allowed to send any requests or notifications to the client until it
     * has responded with an InitializeResult, with the exception that
     * during the initialize request the server is allowed to send the
     * notifications `window/showMessage`, `window/logMessage` and
     * telemetry/event as well as the window/showMessageRequest request to
     * the client. In case the client sets up a progress token in the
     * initialize params (e.g. property workDoneToken) the server is also
     * allowed to use that token (and only that token) using the $/progress
     * notification sent from the server to the client.
     *
     * The initialize request may only be sent once. 
     */
    protected abstract async InitializeResult initialize_async (Client client, InitializeParams init_params) throws Error;

    /**
     * The initialized notification is sent from the client to the server after
     * the client received the result of the initialize request but before the
     * client is sending any other request or notification to the server.
     *
     * The server can use the initialized notification for example to
     * dynamically register capabilities. The initialized notification may only
     * be sent once.
     */
    protected virtual async void initialized_async (Client client) throws Error {
        // do nothing
    }

    /**
     * The document open notification is sent from the client to the server to
     * signal newly opened text documents.
     *
     * The document’s content is now managed by the client and the server must
     * not try to read the document’s content using the document’s Uri. Open in
     * this sense means it is managed by the client. It doesn’t necessarily mean
     * that its content is presented in an editor. An open notification must not
     * be sent more than once without a corresponding close notification send
     * before. This means open and close notification must be balanced and the
     * max open count for a particular textDocument is one. Note that a server’s
     * ability to fulfill requests is independent of whether a text document is
     * open or closed.
     */
    protected abstract async void text_document_did_open_async (Client client, TextDocumentItem text_document) throws Error;

    /**
     * The document change notification is sent from the client to the server to
     * signal changes to a text document. Before a client can change a text
     * document it must claim ownership of its content using the
     * textDocument/didOpen notification (see {@link text_document_did_open_async}).
     *
     * @param text_document     The text document with a version number set.
     * @param content_changes   The actual content changes. The content changes describe single state
     *                          changes to the document. So if there are two content changes c1 (at
     *                          array index 0) and c2 (at array index 1) for a document in state S then
     *                          c1 moves the document from S to S2 and c2 from S2 to S3. So c1 is
     *                          computed on the state S and c2 is computed on the state S2.
     *                          To mirror the content of a document using change events use the following
     *                          approach:
     *                          - start with the same initial content
     *                          - apply the 'textDocument/didChange' notifications in the order you
     *                            receive them.
     *                          - apply the `TextDocumentContentChangeEvent`s in a single notification
     *                            in the order you receive them.
     */
    protected abstract async void text_document_did_change_async (Client client, TextDocumentIdentifier text_document,
                                                                  (unowned TextDocumentContentChangeEvent)[] content_changes) throws Error;
    
    /**
     * The document save notification is sent from the client to the server when
     * the document was saved in the client.
     *
     * @param text_document     The document that was saved.
     * @param text              The content when saved. Depends on whether the
     *                          server has opted to receive this.
     */
    protected virtual async void text_document_did_save_async (Client client, TextDocumentIdentifier text_document,
                                                               string? text) throws Error {
        // do nothing
    }

    /**
     * The document close notification is sent from the client to the server
     * when the document got closed in the client.
     * 
     * The document’s master now exists where the document’s URI points to (e.g.
     * if the document’s URI is a file URI the master now exists on disk). As
     * with the open notification the close notification is about managing the
     * document’s content.  Receiving a close notification doesn’t mean that the
     * document was open in an editor before. A close notification requires a
     * previous open notification to be sent. Note that a server’s ability to
     * fulfill requests is independent of whether a text document is open or
     * closed.
     *
     * @param text_document     The document that was closed.
     */
    protected abstract async void text_document_did_close_async (Client client, TextDocumentIdentifier text_document) throws Error;

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
     * @param text_document the document in which the command was invoked
     * @param range         the range for which the command was invoked
     * @param context       context carrying additional information
     *
     * @return a list of code actions and commands available at the current
     *         range in the document
     */
    protected virtual async Action[]? code_action_async (Client client, TextDocumentIdentifier text_document, Range range, CodeActionContext context) throws Error{
        throw new ProtocolError.METHOD_NOT_IMPLEMENTED ("textDocument/codeAction is not implemented");
    }

    /**
     * The shutdown request is sent from the client to the server. It asks
     * the server to shut down, but to not exit (otherwise the response
     * might not be delivered correctly to the client).
     *
     * There is a separate exit notification that asks the server to exit.
     * Clients must not send any notifications other than exit or requests
     * to a server to which they have sent a shutdown request. Clients
     * should also wait with sending the exit notification until they have
     * received a response from the shutdown request.
     *
     * The server will error with {@link Jsonrpc.ClientError.INVALID_REQUEST} if
     * it receives any requests after a shutdown request.
     */
    protected abstract async void shutdown_async (Client client) throws Error;

    public virtual void exit () {
        loop.quit ();
    }
}
