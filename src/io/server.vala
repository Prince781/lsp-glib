/**
 * A server implementing the Language Server Protocol using {@link GLib.MainLoop}
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

    public Cancellable cancellable { get; private set; default = new Cancellable (); }

    protected Server (MainLoop loop) {
        this.loop = loop;
        this.handle_call.connect ((client, method, id, parameters) => {
            handle_call_async.begin (client, method, id, parameters);
            return !exited;
        });
        this.notification.connect (notification_async);
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
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.DICTIONARY, "DidChangeTextDocumentParams");
                    var cc_variant = expect_property (parameters, "contentChanges", VariantType.ARRAY, "DidChangeTextDocumentParams");
                    var content_changes = new TextDocumentContentChangeEvent[] {};
                    foreach (var cc in cc_variant) {
                        if (cc == null)
                            throw new DeserializeError.INVALID_TYPE ("expected non-null content changes for DidChangeTextDocumentParams");
                        content_changes += new TextDocumentContentChangeEvent.from_variant (cc);
                    }
                    yield text_document_did_change_async (lsp_client, TextDocumentIdentifier.from_variant (tdi_variant), content_changes);
                    break;

                case "textDocument/didClose":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.DICTIONARY, "DidCloseTextDocumentParams");
                    yield text_document_did_close_async (lsp_client, TextDocumentIdentifier.from_variant (tdi_variant));
                    break;

                case "textDocument/didOpen":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.DICTIONARY, "DidOpenTextDocumentParams");
                    yield text_document_did_open_async (lsp_client, new TextDocumentItem.from_variant (tdi_variant));
                    break;
                
                case "textDocument/didSave":
                    var tdi_variant = expect_property (parameters, "textDocument", VariantType.DICTIONARY, "DidSaveTextDocumentParams");
                    var text_variant = lookup_property (parameters, "text", VariantType.STRING, "DidSaveTextDocumentParams");
                    string? text = text_variant != null ? (string) text_variant : null;
                    yield text_document_did_save_async (lsp_client, TextDocumentIdentifier.from_variant (tdi_variant), text);
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

                default:
                    yield reply_error_async (client, id, Jsonrpc.ClientError.METHOD_NOT_FOUND);
                    break;
            }
        } catch (DeserializeError e) {
            warning ("request failed - deserialize params failed - %s", e.message);
            yield reply_error_async (client, id, Jsonrpc.ClientError.INVALID_PARAMS, e.message);
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
                                                                  TextDocumentContentChangeEvent[] content_changes) throws Error;
    
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
