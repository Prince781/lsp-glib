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

G_END_DECLS
