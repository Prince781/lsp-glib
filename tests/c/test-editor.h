#pragma once

#include "lsp-glib.h"

G_BEGIN_DECLS

#define TEST_TYPE_EDITOR (test_editor_get_type ())

typedef struct _TestEditor TestEditor;
typedef struct _TestEditorClass TestEditorClass;

struct _TestEditor
{
  LspEditor parent_instance;

  const gchar *events[16];
  guint n_events;

  LspMessageType shown_type;
  gchar *shown_message;
  LspMessageType logged_type;
  gchar *logged_message;
  gchar *trace_message;
  gchar *trace_verbose;

  gchar *diagnostic_uri;
  gint64 diagnostic_version;
  gboolean has_diagnostic_version;
  guint diagnostic_count;
  gchar *diagnostic_message;

  LspMessageType prompt_type;
  gchar *prompt_message;
  guint prompt_action_count;
  gchar *prompt_first_action;

  gchar *shown_document_uri;
  gboolean shown_document_external;
  gboolean shown_document_take_focus;
  gboolean has_shown_document_selection;
  LspRange shown_document_selection;

  gchar *applied_edit_label;
};

struct _TestEditorClass
{
  LspEditorClass parent_class;
};

GType test_editor_get_type (void);
G_DEFINE_AUTOPTR_CLEANUP_FUNC (TestEditor, g_object_unref)

TestEditor *test_editor_new (void);

G_END_DECLS
