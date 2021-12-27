conf = configuration_data()
conf.set('prefix', get_option('prefix'))
conf.set('libdir', get_option ('libdir'))
conf.set('PROJECT_NAME', 'lsp-glib')
conf.set('PROJECT_VERSION', meson.project_version())
conf.set('API_VERSION', API_VERSION)

sources = [version_file] + files([
  'io/client.vala',
  'io/editor.vala',
  'io/server.vala',
  'types/clientcapabilities.vala',
  'types/command.vala',
  'types/completion.vala',
  'types/diagnostic.vala',
  'types/error.vala',
  'types/initialization.vala',
  'types/location.vala',
  'types/markupcontent.vala',
  'types/message.vala',
  'types/serialization.vala',
  'types/servercapabilities.vala',
  'types/textdocument.vala',
  'types/textedit.vala',
  'types/workspace.vala',
  'types/workspaceedit.vala',
  'library.vala'
])

liblsp_glib = library('lsp-glib-' + API_VERSION,
  sources,
  vala_header: 'lsp-glib.h',
  vala_vapi: 'lsp-glib-' + API_VERSION + '.vapi',
  vala_gir: 'Lsp-' + API_VERSION + '.gir',
  dependencies : dependencies,
  vala_args: [
    '--abi-stability'
    ],
  install: true,
  install_dir: [
    true,
    get_option('includedir') / 'lsp-glib-' + API_VERSION,
    vapidir,
    g_ir_compiler.found()
  ]
)

install_data('lsp-glib.deps',
             install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'vala', 'vapi'))

if g_ir_compiler.found()
  custom_target('liblsp-glib-typelib',
    command: [
      g_ir_compiler,
      '--shared-library', 'liblsp-glib-@0@.so'.format (API_VERSION),
      '--output', '@OUTPUT@',
      meson.current_build_dir() / 'Lsp-' + API_VERSION + '.gir'
    ],
    output: 'Lsp-' + API_VERSION + '.typelib',
    depends: liblsp_glib,
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
endif

pkgconfig.generate(liblsp_glib,
  subdirs: 'lsp-glib-' + API_VERSION,
  version: API_VERSION,
  name: 'lsp-glib',
  filebase: 'lsp-glib-' + API_VERSION,
  requires: PKGCONFIG_DEPS,
  description: 'LSP library built on GLib')

if get_option('enable_valadoc')
  valadoc = find_program('valadoc')
  lsp_glib_docs = custom_target('lsp-glib_apidocs',
    input: sources,
    install: true,
    # FIXME: Installing to tmp, so the target will be built
    #        the problem is we cannot access a subfolder of the
    #        buildtarget via the output parameter.
    #        Find a nicer solution
    install_dir: get_option('datadir') / 'devhelp' / 'books',
    command: [
      valadoc,
      '-o', meson.current_build_dir() / 'Lsp-' + API_VERSION,
      '--doclet',
      'devhelp',
      '@INPUT@',
      '--pkg', 'glib-2.0',
      '--pkg', 'gobject-2.0',
      '--pkg', 'gio-2.0',
      '--pkg', 'jsonrpc-glib-1.0',
      '--force',
      '--use-svg-images',
      '--package-name', 'lsp-glib-' + API_VERSION,
      '--package-version', API_VERSION
    ],
    output: 'Lsp-' + API_VERSION)

  install_subdir(meson.current_build_dir() / 'Lsp-' + API_VERSION / 'lsp-glib-' + API_VERSION,
    install_dir: get_option('datadir') / 'devhelp' / 'books')
endif
