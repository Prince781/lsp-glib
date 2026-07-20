position_test = executable(
  'position-test',
  'vala/position.vala',
  dependencies: lsp_glib_dep,
)

test(
  'position serialization',
  position_test,
  suite: 'vala',
)

diagnostic_test = executable(
  'diagnostic-test',
  'vala/diagnostic.vala',
  dependencies: lsp_glib_dep,
)

test(
  'diagnostic serialization',
  diagnostic_test,
  suite: 'vala',
)

text_document_test = executable(
  'text-document-test',
  'vala/text-document.vala',
  dependencies: lsp_glib_dep,
)

test(
  'text document serialization',
  text_document_test,
  suite: 'vala',
)

workspace_edit_test = executable(
  'workspace-edit-test',
  'vala/workspace-edit.vala',
  dependencies: lsp_glib_dep,
)

test(
  'workspace edit serialization',
  workspace_edit_test,
  suite: 'vala',
)

completion_test = executable(
  'completion-test',
  'vala/completion.vala',
  dependencies: lsp_glib_dep,
)

test(
  'completion serialization',
  completion_test,
  suite: 'vala',
)

initialization_test = executable(
  'initialization-test',
  'vala/initialization.vala',
  dependencies: lsp_glib_dep,
)

test(
  'initialization serialization',
  initialization_test,
  suite: 'vala',
)

server_cancellation_test = executable(
  'server-cancellation-test',
  [
    'vala/server-cancellation.vala',
    'vala/test-stream.vala',
  ],
  dependencies: lsp_glib_dep,
)

test(
  'server cancellation',
  server_cancellation_test,
  suite: 'vala',
)

python = import('python').find_installation(
  'python3',
  modules: ['gi'],
  required: false,
)

if python.found() and g_ir_compiler.found()
  python_test_env = environment()
  python_test_env.prepend(
    'GI_TYPELIB_PATH',
    meson.project_build_root() / 'src',
  )
  python_test_env.prepend(
    'PATH',
    meson.project_build_root() / 'src',
  )

  if host_machine.system() == 'darwin'
    python_test_env.prepend(
      'DYLD_LIBRARY_PATH',
      meson.project_build_root() / 'src',
    )
  elif host_machine.system() != 'windows'
    python_test_env.prepend(
      'LD_LIBRARY_PATH',
      meson.project_build_root() / 'src',
    )
  endif

  test(
    'Python position serialization',
    python,
    args: files('python/position.py'),
    depends: lsp_glib_typelib,
    env: python_test_env,
    suite: 'python',
  )
  test(
    'Python diagnostic serialization',
    python,
    args: files('python/diagnostic.py'),
    depends: lsp_glib_typelib,
    env: python_test_env,
    suite: 'python',
  )
endif
