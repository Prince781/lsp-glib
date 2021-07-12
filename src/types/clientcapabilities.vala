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
    namespace ResourceOperationKind {
        /**
         * Supports creating new files and folders
         */
        public const string CREATE = "create";

        /**
         * Supports renaming existing files and folders.
         */
        public const string RENAME = "rename";

        /**
         * Supports deleting existing files and folders.
         */
        public const string DELETE = "delete";
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
    public struct WorkspaceEditClientCaps {
        /**
         * The client supports versioned document changes in {@link WorkspaceEdit}s
         */
        public bool document_changes;

        /**
         * The resource operations the client supports. Clients should at least
         * support 'create' ({@link ResourceOperationKind.CREATE}), 'rename'
         * ({@link ResourceOperationKind.RENAME}) and 'delete'
         * ({@link ResourceOperationKind.DELETE}) files and folders.
         *
         * @see ResourceOperationKind
         * @since 3.13.0
         */
        public string[]? resource_ops;

        /**
         * The failure handling strategy of a client if applying the workspace
         * edit fails.
         *
         * @since 3.13.0
         */
        public FailureHandlingKind failure_handling;

        /**
         * Whether the client normalizes line endings to the client specific
         * setting.
         *
         * If set to `true` the client will normalize line ending characters in
         * a workspace edit to the client specific new line character(s).
         *
         * @since 3.16.0
         */
        public bool normalizes_line_endings;

        /**
         * Whether the client supports change annotations.
         *
         * @since 3.16.0
         */
        public bool change_annotations;

        /**
         * Whether the client groups edits with equal labels into tree nodes,
         * for instance all edits labelled with "Changes in Strings" would be a
         * tree node.
         */
        public bool change_annotations_group_on_label;
    }

    /**
     * Workspace-specific client capabilities.
     */
    public struct WorkspaceClientCaps {
        /**
         * The client supports applying batch edits to the workspace by
         * supporting the request 'workspace/applyEdit'
         */
        public bool apply_edit;
    }

    /**
     * Completion-specific client capabilities
     */
    public class CompletionClientCaps {
        /**
         * Client supports snippets as insert text.
		 *
         * A snippet can define tab stops and placeholders with `$1`, `$2` and
         * `${3:foo}`. `$0` defines the final tab stop, it defaults to the end
         * of the snippet. Placeholders with equal identifiers are linked, that
         * is typing in one will update others too.
         */
        public bool snippets;

        /**
         * Client supports commit characters on a completion item.
         */
        public bool commit_chars;

        /**
         * Client supports the following content formats for the documentation
         * property. The order describes the preferred format of the client.
         */
        public MarkupKind[]? documentation_formats { get; set; }

        /**
         * Client supports the deprecated property on a completion item.
         */
        public bool deprecated_property;

        /**
         * Client supports the preselect property on a completion item.
         */
        public bool preselect_property;

        /**
         * Client supports the tag property on a completion item. Clients
         * supporting tags have to handle unknown tags gracefully. Clients
         * especially need to preserve unknown tags when sending a completion
         * item back to the server in a resolve call.
         *
         * @since 3.15.0
         */
        public CompletionItemTag supported_tags;

        /**
         * Client supports insert replace edit to control different behavior if
         * a completion item is inserted in the text or should replace text.
		 *
         * @since 3.16.0
         */
        public bool insert_replace;

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
        public bool context;

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
    public struct TextDocumentClientCaps {
        public TextDocumentSyncClientCaps synchronization;

        public CompletionClientCaps completion;
    }

    /**
     * Capabilities of the client / editor.
     */
    public class ClientCaps {
        /**
         * Workspace-specific client capabilities.
         */
        public WorkspaceClientCaps workspace;

        /**
         * Text document-specific client capabilities.
         */
        public TextDocumentClientCaps text_document;
    }
}
