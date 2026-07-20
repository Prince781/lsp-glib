#pragma once

#include <jsonrpc-glib.h>

G_BEGIN_DECLS

void lsp_jsonrpc_client_reply_null_async (
    JsonrpcClient *client,
    GVariant *id,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean lsp_jsonrpc_client_reply_null_finish (
    GAsyncResult *result,
    GError **error);

G_END_DECLS
