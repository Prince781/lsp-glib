#pragma once

#include <gio/gio.h>

G_BEGIN_DECLS

/**
 * lsp_test_create_stream_pair:
 * @server_stream: (out) (transfer full): the server end of the stream pair
 * @client_stream: (out) (transfer full): the client end of the stream pair
 *
 * Creates a portable, in-memory, full-duplex stream pair for protocol tests.
 */
void lsp_test_create_stream_pair (GIOStream **server_stream,
                                  GIOStream **client_stream);

/**
 * lsp_test_server_new:
 *
 * Creates the native protocol-test server used by dynamic binding tests.
 *
 * Returns: (transfer full): a test server
 */
GObject *lsp_test_server_new (void);

/**
 * lsp_test_server_accept_io_stream:
 * @server: the server returned by lsp_test_server_new()
 * @stream: a protocol stream
 */
void lsp_test_server_accept_io_stream (GObject *server,
                                       GIOStream *stream);

/**
 * lsp_test_server_has_document_sync:
 * @server: the server returned by lsp_test_server_new()
 * @uri: the expected text document URI
 *
 * Returns: whether the basic lifecycle and document sync methods completed
 */
gboolean lsp_test_server_has_document_sync (GObject *server,
                                            const gchar *uri);

G_END_DECLS
