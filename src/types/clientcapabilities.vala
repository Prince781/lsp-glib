/* clientcapabilities.vala
 *
 * Copyright 2021 Princeton Ferro <princetonferro@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

namespace Lsp {
    /**
     * The kind of resource operations supported by the client.
     */
    public enum ResourceOperationKind {
        /**
         * Supports creating new files and folders
         */
        CREATE,

        /**
         * Supports renaming existing files and folders.
         */
        RENAME,

        /**
         * Supports deleting existing files and folders.
         */
        DELETE;

        public unowned string to_string () {
            switch (this) {
                case CREATE:
                    return "create";
                case RENAME:
                    return "rename";
                case DELETE:
                    return "delete";
            }

            assert_not_reached ();
        }
    }

    public enum FailureHandlingKind {
        ABORT,
        TRANSACTIONAL,
        TEXT_ONLY_TRANSACTIONAL,
        UNDO;

        public unowned string to_string () {
            switch (this) {
                case ABORT:
                    return "abort";
                case TRANSACTIONAL:
                    return "transactional";
                case TEXT_ONLY_TRANSACTIONAL:
                    return "textOnlyTransactional";
                case UNDO:
                    return "undo";
            }

            assert_not_reached ();
        }

        public bool try_parse (string str, out FailureHandlingKind kind) {
            switch (str) {
                case "abort":
                    kind = ABORT;
                    return true;
                case "transactional":
                    kind = TRANSACTIONAL;
                    return true;
                case "textOnlyTransactional":
                    kind = TEXT_ONLY_TRANSACTIONAL;
                    return true;
                case "undo":
                    kind = UNDO;
                    return true;
                default:
                    kind = ABORT;
                    return false;
            }
        }
    }

    /**
     * Defines what workspace resource operations the client supports.
     * 
     * @see WorkspaceEditClientCaps.resource_ops
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_workspace_edit_client_caps_ref", unref_function = "lsp_workspace_edit_client_caps_unref")]
    public class WorkspaceEditClientCaps {
        private int ref_count = 1;

        public unowned WorkspaceEditClientCaps ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * The client supports versioned document changes in {@link WorkspaceEdit}s
         */
        public bool document_changes { get; set; }

        /**
         * The resource operations the client supports. Clients should at least
         * support 'create' ({@link ResourceOperationKind.CREATE}), 'rename'
         * ({@link ResourceOperationKind.RENAME}) and 'delete'
         * ({@link ResourceOperationKind.DELETE}) files and folders.
         *
         * @see ResourceOperationKind
         * @since 3.13.0
         */
        public string[]? resource_ops { get; set; }

        /**
         * The failure handling strategy of a client if applying the workspace
         * edit fails.
         *
         * @since 3.13.0
         */
        public FailureHandlingKind failure_handling { get; set; }

        /**
         * Whether the client normalizes line endings to the client specific
         * setting.
         *
         * If set to `true` the client will normalize line ending characters in
         * a workspace edit to the client specific new line character(s).
         *
         * @since 3.16.0
         */
        public bool normalizes_line_endings { get; set; }

        /**
         * Whether the client supports change annotations.
         *
         * @since 3.16.0
         */
        public bool change_annotations { get; set; }

        /**
         * Whether the client groups edits with equal labels into tree nodes,
         * for instance all edits labelled with "Changes in Strings" would be a
         * tree node.
         */
        public bool change_annotations_group_on_label { get; set; }

        public WorkspaceEditClientCaps.from_variant (Variant dict) throws DeserializeError {
            Variant? prop;

            if ((prop = dict.lookup_value ("documentChanges", VariantType.BOOLEAN)) != null)
                document_changes = (bool)prop;

            if ((prop = dict.lookup_value ("resourceOperations", VariantType.ARRAY)) != null) {
                string[] ops = {};
                foreach (var op_v in prop)
                    ops += (string)op_v;
                resource_ops = ops;
            }

            if ((prop = dict.lookup_value ("failureHandling", VariantType.STRING)) != null) {
                FailureHandlingKind fh;
                if (FailureHandlingKind.ABORT.try_parse ((string)prop, out fh))
                    failure_handling = fh;
            }

            if ((prop = dict.lookup_value ("normalizesLineEndings", VariantType.BOOLEAN)) != null)
                normalizes_line_endings = (bool)prop;

            if ((prop = dict.lookup_value ("changeAnnotationSupport", VariantType.VARDICT)) != null) {
                change_annotations = true;
                Variant? ca_prop;
                if ((ca_prop = prop.lookup_value ("groupsOnLabel", VariantType.BOOLEAN)) != null)
                    change_annotations_group_on_label = (bool)ca_prop;
            }
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (document_changes)
                dict.insert_value ("documentChanges", true);
            if (resource_ops != null) {
                Variant[] ops = {};
                foreach (unowned var op in resource_ops)
                    ops += op;
                dict.insert_value ("resourceOperations", new Variant.array (VariantType.STRING, ops));
            }
            if (failure_handling != FailureHandlingKind.ABORT)
                dict.insert_value ("failureHandling", failure_handling.to_string ());
            if (normalizes_line_endings)
                dict.insert_value ("normalizesLineEndings", true);
            if (change_annotations) {
                var ca_dict = new VariantDict ();
                if (change_annotations_group_on_label)
                    ca_dict.insert_value ("groupsOnLabel", true);
                dict.insert_value ("changeAnnotationSupport", ca_dict.end ());
            }

            return dict.end ();
        }
    }

    /**
     * Workspace-specific client capabilities.
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_workspace_client_caps_ref", unref_function = "lsp_workspace_client_caps_unref")]
    public class WorkspaceClientCaps {
        private int ref_count = 1;

        public unowned WorkspaceClientCaps ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * The client supports applying batch edits to the workspace by
         * supporting the request 'workspace/applyEdit'
         */
        public bool apply_edit { get; set; }

        /**
         * Capabilities specific to {@link WorkspaceEdit}s.
         *
         * @since 3.13.0
         */
        public WorkspaceEditClientCaps? workspace_edit { get; set; }

        public WorkspaceClientCaps.from_variant (Variant dict) throws DeserializeError {
            Variant? prop;

            if ((prop = dict.lookup_value ("applyEdit", VariantType.BOOLEAN)) != null)
                apply_edit = (bool)prop;

            if ((prop = dict.lookup_value ("workspaceEdit", VariantType.VARDICT)) != null)
                workspace_edit = new WorkspaceEditClientCaps.from_variant (prop);
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (apply_edit)
                dict.insert_value ("applyEdit", true);
            if (workspace_edit != null)
                dict.insert_value ("workspaceEdit", workspace_edit.to_variant ());

            return dict.end ();
        }
    }

    /**
     * Completion-specific client capabilities
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_completion_client_caps_ref", unref_function = "lsp_completion_client_caps_unref")]
    public class CompletionClientCaps {
        private int ref_count = 1;

        public unowned CompletionClientCaps ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * Client supports snippets as insert text.
		 *
         * A snippet can define tab stops and placeholders with `$1`, `$2` and
         * `${3:foo}`. `$0` defines the final tab stop, it defaults to the end
         * of the snippet. Placeholders with equal identifiers are linked, that
         * is typing in one will update others too.
         */
        public bool snippets { get; set; }

        /**
         * Client supports commit characters on a completion item.
         */
        public bool commit_chars { get; set; }

        /**
         * Client supports the following content formats for the documentation
         * property. The order describes the preferred format of the client.
         */
        public MarkupKind[]? documentation_formats { get; set; }

        /**
         * Client supports the deprecated property on a completion item.
         */
        public bool deprecated_property { get; set; }

        /**
         * Client supports the preselect property on a completion item.
         */
        public bool preselect_property { get; set; }

        /**
         * Client supports the tag property on a completion item. Clients
         * supporting tags have to handle unknown tags gracefully. Clients
         * especially need to preserve unknown tags when sending a completion
         * item back to the server in a resolve call.
         *
         * @since 3.15.0
         */
        public CompletionItemTag supported_tags { get; set; }

        /**
         * Client supports insert replace edit to control different behavior if
         * a completion item is inserted in the text or should replace text.
		 *
         * @since 3.16.0
         */
        public bool insert_replace { get; set; }

        /**
         * Indicates which properties a client can resolve lazily on a
         * completion item. Before version 3.16.0 only the predefined
         * properties `documentation` and `detail` could be resolved lazily.
		 *
         * @since 3.16.0
         */
        public string[]? resolve_properties { get; set; }

        /**
         * The client supports the `insertTextMode` property on a completion
         * item to override the whitespace handling mode as defined by the
         * client (see `insertTextMode`).
		 *
         * @since 3.16.0
         */
        public InsertTextMode[]? insert_text_modes { get; set; }

        /**
         * The completion item kind values the client supports. When this
         * property exists the client also guarantees that it will handle
         * values outside its set gracefully and falls back to a default value
         * when unknown.
		 *
         * If this property is not present the client only supports the
         * completion items kinds from `Text` to `Reference` as defined in the
         * initial version of the protocol.
         */
        public CompletionItemKind[]? item_kinds { get; set; }

        /**
         * The client supports to send additional context information for a
         * `textDocument/completion` request.
         */
        public bool context { get; set; }

        public CompletionClientCaps.from_variant (Variant dict) throws DeserializeError {
            Variant? prop;

            if ((prop = dict.lookup_value ("snippet", VariantType.BOOLEAN)) != null)
                snippets = (bool)prop;

            if ((prop = dict.lookup_value ("commitCharactersSupport", VariantType.BOOLEAN)) != null)
                commit_chars = (bool)prop;

            if ((prop = dict.lookup_value ("deprecatedSupport", VariantType.BOOLEAN)) != null)
                deprecated_property = (bool)prop;

            if ((prop = dict.lookup_value ("preselectSupport", VariantType.BOOLEAN)) != null)
                preselect_property = (bool)prop;

            if ((prop = dict.lookup_value ("insertReplaceSupport", VariantType.BOOLEAN)) != null)
                insert_replace = (bool)prop;

            if ((prop = dict.lookup_value ("contextSupport", VariantType.BOOLEAN)) != null)
                context = (bool)prop;

            if ((prop = dict.lookup_value ("resolveSupport", VariantType.VARDICT)) != null) {
                Variant? rp;
                if ((rp = prop.lookup_value ("properties", VariantType.ARRAY)) != null) {
                    string[] props = {};
                    foreach (var p in rp)
                        props += (string)p;
                    resolve_properties = props;
                }
            }

            if ((prop = dict.lookup_value ("documentationFormat", VariantType.ARRAY)) != null) {
                MarkupKind[] formats = {};
                foreach (var f in prop) {
                    if (f.is_of_type (VariantType.STRING)) {
                        switch ((string)f) {
                            case "plaintext":
                                formats += MarkupKind.PLAINTEXT;
                                break;
                            case "markdown":
                                formats += MarkupKind.MARKDOWN;
                                break;
                        }
                    } else if (f.is_of_type (VariantType.INT64))
                        formats += (MarkupKind)(int64)f;
                }
                documentation_formats = formats;
            }
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (snippets)
                dict.insert_value ("snippet", true);
            if (commit_chars)
                dict.insert_value ("commitCharactersSupport", true);
            if (deprecated_property)
                dict.insert_value ("deprecatedSupport", true);
            if (preselect_property)
                dict.insert_value ("preselectSupport", true);
            if (insert_replace)
                dict.insert_value ("insertReplaceSupport", true);
            if (context)
                dict.insert_value ("contextSupport", true);
            if (resolve_properties != null) {
                var rp_dict = new VariantDict ();
                Variant[] props = {};
                foreach (unowned var p in resolve_properties)
                    props += p;
                rp_dict.insert_value ("properties", new Variant.array (VariantType.STRING, props));
                dict.insert_value ("resolveSupport", rp_dict.end ());
            }
            if (documentation_formats != null) {
                Variant[] formats = {};
                foreach (unowned var f in documentation_formats)
                    formats += (int64)f;
                dict.insert_value ("documentationFormat", new Variant.array (VariantType.INT64, formats));
            }

            return dict.end ();
        }
    }

    [Flags]
    public enum TextDocumentSyncClientCaps {
        NONE,

        /**
         * The client supports sending 'will save' notifications.
         */
        WILL_SAVE,

        /**
         * The client supports sending a 'will save' request and waits for
         * a response providing text edits which will be applied to the
         * document before it is saved.
         */
        WILL_SAVE_WAIT_UNTIL,

        /**
         * The client supports 'did save' notifications.
         */
        DID_SAVE
    }

    /**
     * Text document-specific client capabilities.
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_text_document_client_caps_ref", unref_function = "lsp_text_document_client_caps_unref")]
    public class TextDocumentClientCaps {
        private int ref_count = 1;

        public unowned TextDocumentClientCaps ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        public TextDocumentSyncClientCaps synchronization { get; set; }

        public CompletionClientCaps completion { get; set; }

        public TextDocumentClientCaps.from_variant (Variant dict) throws DeserializeError {
            Variant? prop;

            if ((prop = dict.lookup_value ("synchronization", VariantType.VARDICT)) != null) {
                var sync_flags = TextDocumentSyncClientCaps.NONE;
                Variant? sync_prop;
                if ((sync_prop = prop.lookup_value ("willSave", VariantType.BOOLEAN)) != null && (bool)sync_prop)
                    sync_flags |= TextDocumentSyncClientCaps.WILL_SAVE;
                if ((sync_prop = prop.lookup_value ("willSaveWaitUntil", VariantType.BOOLEAN)) != null && (bool)sync_prop)
                    sync_flags |= TextDocumentSyncClientCaps.WILL_SAVE_WAIT_UNTIL;
                if ((sync_prop = prop.lookup_value ("didSave", VariantType.BOOLEAN)) != null && (bool)sync_prop)
                    sync_flags |= TextDocumentSyncClientCaps.DID_SAVE;
                synchronization = sync_flags;
            }

            if ((prop = dict.lookup_value ("completion", VariantType.VARDICT)) != null)
                completion = new CompletionClientCaps.from_variant (prop);
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (synchronization != TextDocumentSyncClientCaps.NONE) {
                var sync_dict = new VariantDict ();
                if (TextDocumentSyncClientCaps.WILL_SAVE in synchronization)
                    sync_dict.insert_value ("willSave", true);
                if (TextDocumentSyncClientCaps.WILL_SAVE_WAIT_UNTIL in synchronization)
                    sync_dict.insert_value ("willSaveWaitUntil", true);
                if (TextDocumentSyncClientCaps.DID_SAVE in synchronization)
                    sync_dict.insert_value ("didSave", true);
                dict.insert_value ("synchronization", sync_dict.end ());
            }

            if (completion != null)
                dict.insert_value ("completion", completion.to_variant ());

            return dict.end ();
        }
    }

    /**
     * Capabilities of the client / editor.
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_client_caps_ref", unref_function = "lsp_client_caps_unref")]
    public class ClientCaps {
        private int ref_count = 1;

        public unowned ClientCaps ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * Workspace-specific client capabilities.
         */
        public WorkspaceClientCaps workspace { get; set; }

        /**
         * Text document-specific client capabilities.
         */
        public TextDocumentClientCaps text_document { get; set; }

        public ClientCaps () {
        }

        public ClientCaps.from_variant (Variant dict) throws DeserializeError {
            Variant? prop;

            if ((prop = dict.lookup_value ("workspace", VariantType.VARDICT)) != null)
                workspace = new WorkspaceClientCaps.from_variant (prop);

            if ((prop = dict.lookup_value ("textDocument", VariantType.VARDICT)) != null)
                text_document = new TextDocumentClientCaps.from_variant (prop);
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (workspace != null)
                dict.insert_value ("workspace", workspace.to_variant ());
            if (text_document != null)
                dict.insert_value ("textDocument", text_document.to_variant ());

            return dict.end ();
        }
    }
}
