/* servercapabilities.vala
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
    public class CompletionOptions {
        /**
         * Most tools trigger completion request automatically without
         * explicitly requesting it using a keyboard shortcut (e.g.
         * Ctrl+Space). Typically they do so when the user starts to type an
         * identifier. For example if the user types `c` in a JavaScript file
         * code complete will automatically pop up present `console` besides
         * others as a completion item. Characters that make up identifiers
         * don't need to be listed here.
         *
         * If code complete should automatically be trigger on characters not being
         * valid inside an identifier (for example `.` in JavaScript) list them in
         * `triggerCharacters`.
         */
        public string[]? triggers { get; set; }

        /**
         * The list of all possible characters that commit a completion. This field
         * can be used if clients don't support individual commit characters per
         * completion item. See client capability
         * `completion.completionItem.commitCharactersSupport`.
         *
         * If a server provides both `allCommitCharacters` and commit characters on
         * an individual completion item the ones on the completion item win.
         *
         * @since 3.2.0
         */
        public string[]? commit_triggers { get; set; }

        /**
         * The server provides support to resolve additional information for a
         * completion item.
         */
        public bool supports_resolve { get; set; }

        public CompletionOptions (bool supports_resolve, string[]? triggers = null) {
            this.supports_resolve = supports_resolve;
            this.triggers = triggers;
        }

        public CompletionOptions.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = null;

            if ((prop = lookup_property (variant, "triggerCharacters", VariantType.STRING_ARRAY, typeof (CompletionOptions).name ())) != null)
                triggers = (string[]) prop;

            if ((prop = lookup_property (variant, "allCommitCharacters", VariantType.STRING_ARRAY, typeof (CompletionOptions).name ())) != null)
                commit_triggers = (string[]) prop;

            if ((prop = lookup_property (variant, "resolveProvider", VariantType.BOOLEAN, typeof (CompletionOptions).name ())) != null)
                supports_resolve = (bool) prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (triggers != null)
                dict.insert_value ("triggerCharacters", triggers);
            if (commit_triggers != null)
                dict.insert_value ("allCommitCharacters", commit_triggers);
            dict.insert_value ("resolveProvider", supports_resolve);

            return dict.end ();
        }
    }

    public class SignatureHelpOptions {
        /**
         * The characters that trigger signature help automatically.
         */
        public string[]? triggers { get; set; }

        /**
         * List of characters that re-trigger signature help.
         *
         * These trigger characters are only active when signature help is already
         * showing. All trigger characters are also counted as re-trigger
         * characters.
         *
         * @since 3.15.0
         */
        public string[]? retriggers { get; set; }

        public SignatureHelpOptions (string[]? triggers = null) {
            this.triggers = triggers;
        }

        public SignatureHelpOptions.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = null;

            if ((prop = lookup_property (variant, "triggerCharacters", VariantType.STRING_ARRAY, typeof (SignatureHelpOptions).name ())) != null)
                triggers = (string[]) prop;

            if ((prop = lookup_property (variant, "retriggerCharacters", VariantType.STRING_ARRAY, typeof (SignatureHelpOptions).name ())) != null)
                retriggers = (string[]) prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (triggers != null)
                dict.insert_value ("triggerCharacters", triggers);
            if (retriggers != null)
                dict.insert_value ("retriggerCharacters", retriggers);

            return dict.end ();
        }
    }

    public class CodeLensOptions {
        /**
         * Code lens has a resolve provider as well.
         */
        public bool supports_resolve { get; set; }

        public CodeLensOptions (bool supports_resolve) {
            this.supports_resolve = supports_resolve;
        }

        public CodeLensOptions.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = null;

            if ((prop = lookup_property (variant, "resolveProvider", VariantType.BOOLEAN, typeof (CodeLensOptions).name ())) != null)
                supports_resolve = (bool) prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("resolveProvider", supports_resolve);

            return dict.end ();
        }
    }

    public class DocumentLinkOptions {
        /**
         * Document links have a resolve provider as well.
         */
        public bool supports_resolve { get; set; }

        public DocumentLinkOptions (bool supports_resolve) {
            this.supports_resolve = supports_resolve;
        }

        public DocumentLinkOptions.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = null;

            if ((prop = lookup_property (variant, "resolveProvider", VariantType.BOOLEAN, typeof (DocumentLinkOptions).name ())) != null)
                supports_resolve = (bool) prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("resolveProvider", supports_resolve);

            return dict.end ();
        }
    }

    public class RenameOptions {
        /**
         * The server supports renames being checked and tested before being
         * executed.
         */
        public bool supports_prepare { get; set; }

        public RenameOptions (bool supports_prepare) {
            this.supports_prepare = supports_prepare;
        }

        public RenameOptions.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = null;

            if ((prop = lookup_property (variant, "prepareProvider", VariantType.BOOLEAN, typeof (RenameOptions).name ())) != null)
                supports_prepare = (bool) prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("prepareProvider", supports_prepare);

            return dict.end ();
        }
    }

    /**
     * The capabilities of the language server.
     */
    public class ServerCaps {
        /**
         * Defines how text documents are synced.
         */
        public TextDocumentSyncKind text_document_sync { get; set; }

        /**
         * The server provides completion support.
         */
        public CompletionOptions? completion { get; set; }

        /**
         * The server provides hover support.
         */
        public bool hover { get; set; }

        /**
         * The server provides signature help support.
         */
        public SignatureHelpOptions? signature_help { get; set; }

        /**
         * The server provides goto-declaration support.
         */
        public bool declaration { get; set; }

        /**
         * The server provides goto-definition support.
         */
        public bool definition { get; set; }

        /**
         * The server provides goto-type-definition support.
         */
        public bool type_definition { get; set; }

        /**
         * The server provides goto-implementation support.
         */
        public bool implementation { get; set; }

        /**
         * The server provides find references support.
         */
        public bool references { get; set; }

        /**
         * The server provides document highlight support.
         */
        public bool document_highlight { get; set; }

        /**
         * The server provides document symbol support.
         */
        public bool document_symbol { get; set; }

        /**
         * The server provides code actions.
         */
        public bool code_action { get; set; }

        /**
         * The server provides code lens.
         */
        public CodeLensOptions? code_lens { get; set; }

        /**
         * The server provides document links.
         */
        public DocumentLinkOptions? document_link { get; set; }

        /**
         * The server provides rename support.
         */
        public RenameOptions? rename { get; set; }

        /**
         * The server provides workspace symbol support.
         */
        public bool workspace_symbol { get; set; }

        public ServerCaps.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = null;

            text_document_sync = (TextDocumentSyncKind) expect_property (variant, "textDocumentSync", VariantType.INT64, typeof (ServerCaps).name ());

            if ((prop = lookup_property (variant, "completionProvider", VariantType.VARDICT, typeof (ServerCaps).name ())) != null)
                completion = new CompletionOptions.from_variant (prop);

            if ((prop = lookup_property (variant, "hoverProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                hover = (bool) prop;

            if ((prop = lookup_property (variant, "signatureHelpProvider", VariantType.VARDICT, typeof (ServerCaps).name ())) != null)
                signature_help = new SignatureHelpOptions.from_variant (prop);

            if ((prop = lookup_property (variant, "declarationProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                declaration = (bool) prop;

            if ((prop = lookup_property (variant, "definitionProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                definition = (bool) prop;

            if ((prop = lookup_property (variant, "typeDefinitionProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                type_definition = (bool) prop;

            if ((prop = lookup_property (variant, "implementationProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                implementation = (bool) prop;

            if ((prop = lookup_property (variant, "referencesProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                references = (bool) prop;

            if ((prop = lookup_property (variant, "documentHighlightProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                document_highlight = (bool) prop;

            if ((prop = lookup_property (variant, "documentSymbolProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                document_symbol = (bool) prop;

            if ((prop = lookup_property (variant, "codeActionProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                code_action = (bool) prop;

            if ((prop = lookup_property (variant, "codeLensProvider", VariantType.VARDICT, typeof (ServerCaps).name ())) != null)
                code_lens = new CodeLensOptions.from_variant (prop);

            if ((prop = lookup_property (variant, "documentLinkProvider", VariantType.VARDICT, typeof (ServerCaps).name ())) != null)
                document_link = new DocumentLinkOptions.from_variant (prop);

            if ((prop = lookup_property (variant, "renameProvider", VariantType.VARDICT, typeof (ServerCaps).name ())) != null)
                rename = new RenameOptions.from_variant (prop);

            if ((prop = lookup_property (variant, "workspaceSymbolProvider", VariantType.BOOLEAN, typeof (ServerCaps).name ())) != null)
                workspace_symbol = (bool) prop;
        }
        

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("textDocumentSync", new Variant.int64 (text_document_sync));
            if (completion != null)
                dict.insert_value ("completionProvider", completion.to_variant ());
            dict.insert_value ("hoverProvider", hover);
            if (signature_help != null)
                dict.insert_value ("signatureHelpProvider", signature_help.to_variant ());
            dict.insert_value ("declarationProvider", declaration);
            dict.insert_value ("definitionProvider", definition);
            dict.insert_value ("typeDefinitionProvider", type_definition);
            dict.insert_value ("implementationProvider", implementation);
            dict.insert_value ("referencesProvider", references);
            dict.insert_value ("documentHighlightProvider", document_highlight);
            dict.insert_value ("documentSymbolProvider", document_symbol);
            dict.insert_value ("codeActionProvider", code_action);
            if (code_lens != null)
                dict.insert_value ("codeLensProvider", code_lens.to_variant ());
            if (document_link != null)
                dict.insert_value ("documentLinkProvider", document_link.to_variant ());
            if (rename != null)
                dict.insert_value ("renameProvider", rename.to_variant ());
            dict.insert_value ("workspaceSymbolProvider", workspace_symbol);

            return dict.end ();
        }
    }
}
