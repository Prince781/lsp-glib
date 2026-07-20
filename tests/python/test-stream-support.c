#include "test-stream-support.h"

#include "../c/test-stream.h"

void
lsp_test_create_stream_pair (GIOStream **server_stream,
                             GIOStream **client_stream)
{
  create_test_stream_pair (server_stream, client_stream);
}
