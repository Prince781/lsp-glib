#include "jsonrpc-reply.h"

void
lsp_jsonrpc_client_reply_null_async (JsonrpcClient *client,
                                     GVariant *id,
                                     GCancellable *cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data)
{
  jsonrpc_client_reply_async (
      client,
      id,
      NULL,
      cancellable,
      callback,
      user_data);
}

gboolean
lsp_jsonrpc_client_reply_null_finish (GAsyncResult *result,
                                      GError **error)
{
  g_autoptr (GObject) source = g_async_result_get_source_object (result);

  g_return_val_if_fail (JSONRPC_IS_CLIENT (source), FALSE);
  return jsonrpc_client_reply_finish (
      JSONRPC_CLIENT (source),
      result,
      error);
}
