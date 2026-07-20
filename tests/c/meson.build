c_serialization_test = executable(
  'c-serialization-test',
  [
    'serialization.c',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'C serialization',
  c_serialization_test,
  suite: 'c',
)

c_completion_test = executable(
  'c-completion-test',
  [
    'completion.c',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'C completion serialization',
  c_completion_test,
  suite: 'c',
)

c_workspace_edit_test = executable(
  'c-workspace-edit-test',
  [
    'workspace-edit.c',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'C workspace edit serialization',
  c_workspace_edit_test,
  suite: 'c',
)

c_advanced_test = executable(
  'c-advanced-test',
  [
    'advanced.c',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'C advanced serialization',
  c_advanced_test,
  suite: 'c',
)

c_server_test = executable(
  'c-server-test',
  [
    'server.c',
    'test-server.c',
    'test-stream.c',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'C server JSON-RPC dispatch',
  c_server_test,
  suite: 'c',
)

c_editor_test = executable(
  'c-editor-test',
  [
    'editor.c',
    'test-editor.c',
    'test-server.c',
    'test-stream.c',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'C Editor and Server document sync',
  c_editor_test,
  suite: 'c',
)
