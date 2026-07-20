python = import('python').find_installation('python3')

lsp_glib_gir = custom_target(
  'liblsp-glib-gir',
  output: 'Lsp-' + API_VERSION + '.gir',
  command: [
    python,
    files('../types/patch-boxed-gir.py'),
    meson.current_build_dir() / '..' / 'Lsp-' + API_VERSION + '.gir',
    '@OUTPUT@',
    files('../types/boxed-types.def'),
  ],
  depends: liblsp_glib,
  install: true,
  install_dir: get_option('datadir') / 'gir-1.0',
)
