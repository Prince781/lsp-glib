python = import('python').find_installation(
  'python3',
  modules: ['gi'],
  required: false,
)

g_ir_scanner = find_program('g-ir-scanner', required: false)

if python.found() and g_ir_compiler.found() and g_ir_scanner.found()
  gnome = import('gnome')
  python_test_support = shared_library(
    'lsp-test-support',
    [
      'test-stream-support.c',
      '../c/test-stream.c',
    ],
    dependencies: dependency('gio-2.0'),
    install: false,
  )
  python_test_support_gir = gnome.generate_gir(
    python_test_support,
    sources: files('test-stream-support.h'),
    namespace: 'LspTest',
    nsversion: '1.0',
    identifier_prefix: 'LspTest',
    symbol_prefix: 'lsp_test',
    includes: ['Gio-2.0'],
    env: {'GI_SCANNER_DISABLE_CACHE': '1'},
    install: false,
  )

  python_test_env = environment()
  python_test_env.prepend(
    'GI_TYPELIB_PATH',
    meson.current_build_dir(),
  )
  python_test_env.prepend(
    'GI_TYPELIB_PATH',
    meson.project_build_root() / 'src',
  )
  python_test_env.prepend(
    'PATH',
    meson.current_build_dir(),
  )
  python_test_env.prepend(
    'PATH',
    meson.project_build_root() / 'src',
  )

  if host_machine.system() == 'darwin'
    python_test_env.prepend(
      'DYLD_LIBRARY_PATH',
      meson.current_build_dir(),
    )
    python_test_env.prepend(
      'DYLD_LIBRARY_PATH',
      meson.project_build_root() / 'src',
    )
  elif host_machine.system() != 'windows'
    python_test_env.prepend(
      'LD_LIBRARY_PATH',
      meson.current_build_dir(),
    )
    python_test_env.prepend(
      'LD_LIBRARY_PATH',
      meson.project_build_root() / 'src',
    )
  endif

  test(
    'Python position serialization',
    python,
    args: files('position.py'),
    depends: lsp_glib_typelib,
    env: python_test_env,
    suite: 'python',
  )
  test(
    'Python diagnostic serialization',
    python,
    args: files('diagnostic.py'),
    depends: lsp_glib_typelib,
    env: python_test_env,
    suite: 'python',
  )
  test(
    'Python typed serialization',
    python,
    args: files('types.py'),
    depends: lsp_glib_typelib,
    env: python_test_env,
    suite: 'python',
  )
  test(
    'Python server JSON-RPC dispatch',
    python,
    args: files('server.py'),
    depends: [
      lsp_glib_typelib,
      python_test_support_gir,
    ],
    env: python_test_env,
    suite: 'python',
  )
endif
