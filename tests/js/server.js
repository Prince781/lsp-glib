import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Lsp from 'gi://Lsp?version=3.0';
import LspTest from 'gi://LspTest?version=1.0';

const assert = (condition, message) => {
    if (!condition)
        throw new Error(message);
};

const waitUntil = async predicate => {
    const deadline = GLib.get_monotonic_time() + 5 * GLib.USEC_PER_SEC;

    while (!predicate()) {
        if (GLib.get_monotonic_time() >= deadline)
            throw new Error('timed out waiting for protocol dispatch');
        await new Promise(resolve => {
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1, () => {
                resolve();
                return GLib.SOURCE_REMOVE;
            });
        });
    }
};

// GJS cannot implement GObject async vfuncs that expose the callback in the
// virtual method ABI. Use the shared native Server to exercise the supported
// side of the binding: a GJS Editor issuing real requests and notifications.
const asyncMethods = [
    ['initialize_with_params_async', 'initialize_with_params_finish'],
    ['initialized_async', 'initialized_finish'],
    ['open_text_document_async', 'open_text_document_finish'],
    ['edit_text_document_async', 'edit_text_document_finish'],
    ['save_text_document_async', 'save_text_document_finish'],
    ['close_text_document_async', 'close_text_document_finish'],
    ['shutdown_async', 'shutdown_finish'],
    ['exit_async', 'exit_finish'],
];

for (const [asyncMethod, finishMethod] of asyncMethods)
    Gio._promisify(Lsp.Editor.prototype, asyncMethod, finishMethod);

const [serverStream, editorStream] = LspTest.create_stream_pair();
const server = LspTest.server_new();
const editor = Lsp.Editor.new();
LspTest.server_accept_io_stream(server, serverStream);
editor.accept_io_stream(editorStream);

const workspaceUri = GLib.Uri.parse('file:///workspace', GLib.UriFlags.NONE);
const initParams = Lsp.InitializeParams.new(null);
initParams.set_locale('en-US');
initParams.set_root_uri(workspaceUri);
initParams.set_workspaces([
    Lsp.WorkspaceFolder.new(workspaceUri, 'workspace'),
]);

await editor.initialize_with_params_async(initParams);
await editor.initialized_async();

const uri = GLib.Uri.parse('file:///server-test.js', GLib.UriFlags.NONE);
await editor.open_text_document_async(
    uri,
    Lsp.LanguageId.JAVASCRIPT,
    'const before = true;',
);

const change = new Lsp.TextDocumentContentChangeEvent();
change.init(null, 'const after = true;');
await editor.edit_text_document_async(uri, 2, [change]);
await editor.save_text_document_async(uri, 'const saved = true;');
await editor.close_text_document_async(uri);
await editor.shutdown_async();
await editor.exit_async();

assert(editor.is_shutting_down, 'Editor did not enter shutdown state');
assert(editor.exited, 'Editor did not enter exited state');
await waitUntil(() =>
    LspTest.server_has_document_sync(server, uri.to_string()));
