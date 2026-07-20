#include "test-stream-support.h"

#include "../c/test-server.h"
#include "../c/test-stream.h"

void
lsp_test_create_stream_pair (GIOStream **server_stream,
                             GIOStream **client_stream)
{
  create_test_stream_pair (server_stream, client_stream);
}

GObject *
lsp_test_server_new (void)
{
  g_autoptr (GMainLoop) loop = g_main_loop_new (NULL, FALSE);

  return G_OBJECT (test_server_new (loop));
}

void
lsp_test_server_accept_io_stream (GObject *server,
                                  GIOStream *stream)
{
  g_return_if_fail (G_TYPE_CHECK_INSTANCE_TYPE (
      server,
      TEST_TYPE_SERVER));

  jsonrpc_server_accept_io_stream (JSONRPC_SERVER (server), stream);
}

gboolean
lsp_test_server_has_document_sync (GObject *server,
                                   const gchar *uri)
{
  TestServer *self;
  static const gchar *expected_events[] = {
    "initialize",
    "initialize-finish",
    "initialized",
    "initialized-finish",
    "did-open",
    "did-open-finish",
    "did-change",
    "did-change-finish",
    "did-save",
    "did-save-finish",
    "did-close",
    "did-close-finish",
    "shutdown",
    "shutdown-finish",
    "exit",
  };

  g_return_val_if_fail (G_TYPE_CHECK_INSTANCE_TYPE (
      server,
      TEST_TYPE_SERVER),
      FALSE);
  self = (TestServer *) server;

  if (self->n_events != G_N_ELEMENTS (expected_events))
    return FALSE;
  for (guint i = 0; i < self->n_events; i++)
    {
      if (g_strcmp0 (self->events[i], expected_events[i]) != 0)
        return FALSE;
    }

  return g_strcmp0 (self->initialize_locale, "en-US") == 0 &&
      g_strcmp0 (self->initialize_root_uri, "file:///workspace") == 0 &&
      self->initialize_workspace_count == 1 &&
      g_strcmp0 (self->opened_uri, uri) == 0 &&
      self->opened_language_id == LSP_LANGUAGE_ID_JAVASCRIPT &&
      self->opened_version == 1 &&
      g_strcmp0 (self->opened_text, "const before = true;") == 0 &&
      g_strcmp0 (self->changed_uri, uri) == 0 &&
      self->changed_version == 2 &&
      self->changed_content_count == 1 &&
      g_strcmp0 (self->changed_text, "const after = true;") == 0 &&
      g_strcmp0 (self->saved_uri, uri) == 0 &&
      g_strcmp0 (self->saved_text, "const saved = true;") == 0 &&
      g_strcmp0 (self->closed_uri, uri) == 0;
}
