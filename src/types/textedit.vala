/* textedit.vala
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
     * A textual edit applicable to a text document.
     */
    [Compact (opaque=true)]
    public class TextEdit {
        /**
         * The range of the text document to be manipulated. To insert text
         * into a document create a range where start === end.
         */
        public Range range { get; set; }

        /**
         * The string to be inserted. For delete operations use an empty
         * string.
         */
        public string new_text { get; set; }

        /**
         * An identifier referring to a change annotation managed by a workspace
         * edit.
         *
         * Usually clients provide options to group the changes along the
         * annotations they are associated with. To support this in the protocol an
         * edit or resource operation refers to a change annotation using an
         * identifier and not the change annotation literal directly. This allows
         * servers to use the identical annotation across multiple edits or
         * resource operations which then allows clients to group the operations
         * under that change annotation. The actual change annotations together
         * with their identifers are managed by the workspace edit via the new
         * property changeAnnotations.
         *
         * Support for this is guarded by the client capability
         * `workspace.workspaceEdit.changeAnnotationSupport`. If a client doesn’t
         * signal the capability, servers shouldn’t send this back to the client
         * and should leave this set to `null`.
         *
         * @since 3.16.0
         */
        public string? annotation_id { get; set; }

        public TextEdit (Range range, string new_text, string? annotation_id = null) {
            this.range = range;
            this.new_text = new_text;
            this.annotation_id = null;
        }
    }

    /**
     * Additional information that describes document changes.
     *
     * @since 3.16.0
     */
    [Compact (opaque=true)]
    public class ChangeAnnotation {
        /**
         * A human-readable string describing the actual change. The string is
         * rendered prominent in the user interface.
         */
        public string label { get; set; }

        /**
         * A flag which indicates that user confirmation is needed before
         * applying the change.
         */
        public bool needs_confirmation { get; set; }

        /**
         * A human-readable string which is rendered less prominent in the user
         * interface.
         */
        public string? description { get; set; }

        public ChangeAnnotation (string label, bool needs_confirmation = false, string? description = null) {
            this.label = label;
            this.needs_confirmation = needs_confirmation;
            this.description = description;
        }
    }

    /**
     * Describes textual changes on a single text document.
     *
     * The text document may be referred to as a {@link TextDocumentIdentifier}
     * to allow clients to check the text document version before an edit is
     * applied. A {@link TextDocumentEdit} describes all changes on a version
     * Si and after they are applied move the document to version Si+1. So the
     * creator of a {@link TextDocumentEdit} doesn’t need to sort the array of
     * edits or do any kind of ordering. However the edits must be non
     * overlapping.
     */
    public class TextDocumentEdit : ResourceOperation {
        /**
         * The text document to change. This may be a versioned {@link TextDocumentIdentifier}
         */
        public TextDocumentIdentifier text_document { get; set; }

        private TextEdit[] _edits;

        /**
         * The edits to be applied.
         *
         * Support for annotated text edits is guarded by the client capability
         * `workspace.workspaceEdit.changeAnnotationSupport`
         */
        public TextEdit[] edits {
            get { return _edits; }
            owned set {
                for (var i = 0; i < value.length; i++)
                    _edits += (owned)value[i];
            }
        }

        public TextDocumentEdit (TextDocumentIdentifier text_document, TextEdit[] edits) {
            this.text_document = text_document;
            this._edits = {};

            for (var i = 0; i < edits.length; i++)
                this._edits += (owned)edits[i];
        }
    }
}
