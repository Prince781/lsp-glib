#pragma once

#include "lsp-glib.h"

G_BEGIN_DECLS

#define TEST_TYPE_SERVER (test_server_get_type ())

typedef struct _TestServer TestServer;
typedef struct _TestServerClass TestServerClass;

struct _TestServer
{
  LspServer parent_instance;

  const gchar *events[64];
  guint n_events;

  LspClient *peer_client;

  gchar *initialize_locale;
  gchar *initialize_root_uri;
  guint initialize_workspace_count;

  gchar *opened_uri;
  LspLanguageId opened_language_id;
  gint64 opened_version;
  gchar *opened_text;

  gchar *changed_uri;
  gint64 changed_version;
  guint changed_content_count;
  gchar *changed_text;

  gchar *saved_uri;
  gchar *saved_text;

  gchar *closed_uri;
};

struct _TestServerClass
{
  LspServerClass parent_class;
};

GType test_server_get_type (void);
G_DEFINE_AUTOPTR_CLEANUP_FUNC (TestServer, g_object_unref)

TestServer *test_server_new (GMainLoop *loop);

G_END_DECLS
