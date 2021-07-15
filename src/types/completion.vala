/* completion.vala
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
     * How whitespace and indentation is handled during completion item
     * insertion.
     *
     * @since 3.16.0
     */
    public enum InsertTextMode {
        UNSET               = 0,

        /**
         * The insertion or replacement string is taken as it is.
         *
         * If the value is multi line the lines below the cursor will be
         * inserted using the indentation defined in the string value.  The
         * client will not apply any kind of adjustments to the string.
         */
        AS_IS               = 1,

        /**
         * The editor adjusts leading whitespace of new lines so that
         * they match the indentation up to the cursor of the line for
         * which the item is accepted.
         *
         * Consider a line like this: <2tabs><cursor><3tabs>foo. Accepting a
         * multi line completion item is indented using 2 tabs and all
         * following lines inserted will be indented using 2 tabs as well.
         */
        ADJUST_INDENTATION  = 2
    }

    public enum InsertTextFormat {
        UNSET       = 0,

        /**
         * The primary text to be inserted is treated as a plain string.
         */
        PLAINTEXT   = 1,

        /**
         * The primary text to be inserted is treated as a snippet.
         *
         * A snippet can define tab stops and placeholders with `$1`, `$2`
         * and `${3:foo}`. `$0` defines the final tab stop, it defaults to
         * the end of the snippet. Placeholders with equal identifiers are linked,
         * that is typing in one will update others too.
         */
        SNIPPET     = 2
    }

    /**
     * The kind of a completion entry.
     */
    public enum CompletionItemKind {
        UNSET           = 0,
        TEXT            = 1,
        METHOD          = 2,
        FUNCTION        = 3,
        CONSTRUCTOR     = 4,
        FIELD           = 5,
        VARIABLE        = 6,
        CLASS           = 7,
        INTERFACE       = 8,
        MODULE          = 9,
        PROPERTY        = 10,
        UNIT            = 11,
        VALUE           = 12,
        ENUM            = 13,
        KEYWORD         = 14,
        SNIPPET         = 15,
        COLOR           = 16,
        FILE            = 17,
        REFERENCE       = 18,
        FOLDER          = 19,
        ENUM_MEMBER     = 20,
        CONSTANT        = 21,
        STRUCT          = 22,
        EVENT           = 23,
        OPERATOR        = 24,
        TYPE_PARAMETER  = 25
    }

    [Flags]
    public enum CompletionItemTag {
        NONE,
        DEPRECATED
    }

    public class CompletionItem {
        public string label { get; set; }

        public CompletionItemKind kind { get; set; }

        public CompletionItemTag tags { get; set; }

        public string? detail { get; set; }

        public MarkupContent? documentation { get; set; }

        public bool preselect { get; set; }

        /**
         * A string that should be inserted into a document when selecting
         * this completion. When `falsy` the label is used as the insert
         * text for this item.
         *
         * The `insertText` is subject to interpretation by the client side.  Some
         * tools might not take the string literally. For example VS Code when code
         * complete is requested in this example `con<cursor position>` and a
         * completion item with an `insertText` of `console` is provided it will
         * only insert `sole`. Therefore it is
         * recommended to use `textEdit` instead since it avoids additional client
         * side interpretation.
         */
        public string? insert_text { get; set; }

        /**
         * The format of the insert text. The format applies to both the
         * `insertText` property and the `newText` property of a provided
         * `textEdit`. If omitted defaults to `InsertTextFormat.PlainText`.
         */
        public InsertTextFormat insert_text_format { get; set; }

        /**
         * How whitespace and indentation is handled during completion
         * item insertion. If not provided the client's default value depends on
         * the `textDocument.completion.insertTextMode` client capability.
         *
         * @since 3.16.0
         */
        public InsertTextMode insert_text_mode { get; set; }

        /**
         * An edit which is applied to a document when selecting this completion.
         * When an edit is provided the value of `insertText` is ignored.
         *
         * *Note:* The range of the edit must be a single line range and it must
         * contain the position at which completion has been requested.
         *
         * Most editors support two different operations when accepting a completion
         * item. One is to insert a completion text and the other is to replace an
         * existing text with a completion text. Since this can usually not be
         * predetermined by a server it can report both ranges. Clients need to
         * signal support for `InsertReplaceEdit`s via the
         * `textDocument.completion.completionItem.insertReplaceSupport` client
         * capability property.
         *
         * *Note 1:* The text edit's range as well as both ranges from an insert
         * replace edit must be a [single line] and they must contain the position
         * at which completion has been requested.
         * *Note 2:* If an `InsertReplaceEdit` is returned the edit's insert range
         * must be a prefix of the edit's replace range, that means it must be
         * contained and starting at the same position.
         */
        public TextEdit? text_edit { get; owned set; }

        /**
         * An optional array of additional text edits that are applied when
         * selecting this completion. Edits must not overlap (including the same
         * insert position) with the main edit nor with themselves.
         *
         * Additional text edits should be used to change text unrelated to the
         * current cursor position (for example adding an import statement at the
         * top of the file if the completion item will insert an unqualified type).
         */
        public TextEdit[]? additional_text_edits { get; owned set; }

        /**
         * An optional set of characters that when pressed while this completion is
         * active will accept it first and then type that character. *Note* that all
         * commit characters should have `length=1` and that superfluous characters
         * will be ignored.
         */
        public string[]? commit_chars { get; set; }

        /**
         * An optional command that is executed *after* inserting this completion.
         * *Note* that additional modifications to the current document should be
         * described with the additionalTextEdits-property.
         */
        public Command? command { get; set; }

        /**
         * A data entry field that is preserved on a completion item between
         * a completion and a completion resolve request.
         */
        public Variant? data { get; set; }
    }
}
