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

### Protocol Support

#### Base Protocol

- [x] `$/cancelRequest` (server)

#### Lifecycle Messages

- [x] `initialize`
- [x] `initialized`
- [ ] `client/registerCapability`
- [ ] `client/unregisterCapability`
- [x] `$/setTrace`
- [x] `$/logTrace`
- [x] `shutdown`
- [x] `exit`

#### Document Synchronization

- [x] `textDocument/didOpen`
- [x] `textDocument/didChange`
- [ ] `textDocument/willSave` (client capability only)
- [ ] `textDocument/willSaveWaitUntil`
- [x] `textDocument/didSave`
- [x] `textDocument/didClose`
- [ ] `textDocument/didRename`

#### Language Features

- [x] `textDocument/completion`
- [ ] `completionItem/resolve`
- [x] `textDocument/hover`
- [x] `textDocument/signatureHelp`
- [x] `textDocument/codeAction`
- [ ] `codeAction/resolve`
- [x] `textDocument/publishDiagnostics`
- [ ] `textDocument/pullDiagnostics`
- [ ] `textDocument/declaration` (capability field only)
- [ ] `textDocument/definition` (capability field only)
- [ ] `textDocument/typeDefinition` (capability field only)
- [ ] `textDocument/implementation` (capability field only)
- [ ] `textDocument/references` (capability field only)
- [ ] `textDocument/documentHighlight` (capability field only)
- [ ] `textDocument/documentSymbol` (capability field only)
- [ ] `textDocument/codeLens` (types only)
- [ ] `codeLens/resolve`
- [ ] `textDocument/foldingRange`
- [ ] `textDocument/selectionRange`
- [ ] `textDocument/documentLink` (types only)
- [ ] `documentLink/resolve`
- [ ] `textDocument/documentColor`
- [ ] `textDocument/colorPresentation`
- [ ] `textDocument/formatting` (capability field only)
- [ ] `textDocument/rangeFormatting` (capability field only)
- [ ] `textDocument/onTypeFormatting` (types only)
- [ ] `textDocument/rename` (types only)
- [ ] `textDocument/prepareRename`
- [ ] `textDocument/semanticTokens`
- [ ] `textDocument/moniker`
- [ ] `textDocument/inlineValue`
- [ ] `textDocument/inlayHint`
- [ ] `textDocument/prepareCallHierarchy`
- [ ] `textDocument/prepareTypeHierarchy`
- [ ] `textDocument/linkedEditingRange`

#### Workspace Features

- [ ] `workspace/symbol` (capability field only)
- [ ] `workspace/executeCommand`
- [ ] `workspace/applyEdit`
- [ ] `workspace/didChangeConfiguration`
- [ ] `workspace/didChangeWatchedFiles`
- [ ] `workspace/didChangeWorkspaceFolders`
- [ ] `workspace/willCreateFiles`
- [ ] `workspace/didCreateFiles`
- [ ] `workspace/willRenameFiles`
- [ ] `workspace/didRenameFiles`
- [ ] `workspace/willDeleteFiles`
- [ ] `workspace/didDeleteFiles`
- [ ] `workspace/didChangeConfiguration`
- [ ] `workspace/textDocumentContent`

#### Window Features

- [x] `window/showMessage`
- [x] `window/showMessageRequest`
- [x] `window/logMessage`
- [x] `window/showDocument`

#### Telemetry

- [ ] `telemetry/event`

### Workflow

Install Uncrustify and enable the tracked Git hooks for this checkout:

```sh
git config core.hooksPath .githooks
```

The pre-commit hook checks staged Vala files against `.uncrustify.cfg`. It
reports files that need formatting without modifying the working tree or the
index. GitHub Actions runs the same check for Vala files changed by each pull
request.

### Docs

Run `meson build && meson compile -C build`. Docs will be located in `build/src/Lsp-3.0`.

### Tests

Run all available tests with `meson test -C build`. Tests can also be run by
language:

```sh
meson test -C build --suite vala
meson test -C build --suite c
meson test -C build --suite python
meson test -C build --suite js
```
