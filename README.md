# lsp-glib

LSP library built on GLib. Designed for both editors and servers.

Design ideas:
- Hide JSON-RPC protocol as much as possible from the user
  - protocol functions are fully typed
  - protocol functions throw errors instead of explicitly sending error
    messages to client
- Fully asynchronous API
- Use GVariant serialization for data types with
  `to_variant()` / `from_variant()` functions
- Make C API ergonomic and limit memory requirements:
  - Avoid GObject as much as possible
  - Flatten LSP data structures where it makes sense to avoid excess
    pointer chasing
  - No use of `libgee`. Prefer built-in GLib data structures


### Docs

Run `meson build && meson compile -C build`. Docs will be located in `build/src/Lsp-3.0`.
