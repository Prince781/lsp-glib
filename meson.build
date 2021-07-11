project('lsp-glib', 'vala', 'c',
  version: '3.16.0-alpha',
  license: 'LGPL-2.1-or-later')

dependencies = [
  dependency('glib-2.0', version: '>= 2.66'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('json-glib-1.0', version: '>= 1.4.4'),
  dependency('jsonrpc-glib-1.0', version: '>= 3.28')
]

pkgconfig = import('pkgconfig')

PKGCONFIG_DEPS = ['glib-2.0', 'gobject-2.0', 'gio-2.0', 'json-glib-1.0']
API_VERSION = '3.0'
vapidir = get_option('datadir') / 'vala' / 'vapi'

add_project_arguments(['--enable-experimental', '--fatal-warnings'], language: 'vala')

g_ir_compiler = find_program('g-ir-compiler', required: false)

version_file = vcs_tag(input: 'version.vala.in',
                       output: 'version.vala',
                       command: ['git', 'describe', '--tags', '--dirty'])

subdir('src')
