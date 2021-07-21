import gi
gi.require_version('Lsp', '3.0')

from gi.repository import Lsp, GLib

pos = [Lsp.Position() for _ in range(0, 2)]
pos[0].init(1, 2)
pos[1].init(3, 4)

lsp_range = Lsp.Range()
lsp_range.init(*pos)

diag = Lsp.Diagnostic.new('diagnostic message', lsp_range)

loc = Lsp.Location()
loc.init(GLib.Uri.parse('file:///dev/null', GLib.UriFlags.NONE), lsp_range)

related = [Lsp.DiagnosticRelatedInformation()]
related[0].init(loc, 'related message')

# diag.related_information.append(related[0])
diag.tags.insert(0, Lsp.DiagnosticTag.DEPRECATED)

print('diag =', diag.to_variant())
