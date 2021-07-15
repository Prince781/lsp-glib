import gi
gi.require_version('Lsp', '3.0')
from gi.repository import Lsp

pos = Lsp.Position()
pos.init(3, 1)
print(pos.to_variant())

pos.line = 8
pos.character = 20
print(pos.to_variant())
