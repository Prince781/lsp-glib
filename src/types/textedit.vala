namespace Lsp {
    /**
     * A textual edit applicable to a text document.
     */
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

        public TextEdit (Range range, string new_text) {
            this.range = range;
            this.new_text = new_text;
        }
    }

    /**
     * Additional information that describes document changes.
     *
     * @since 3.16.0
     */
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

        public ChangeAnnotation (string label) {
            this.label = label;
        }
    }

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
     * and should send {@link TextEdit} instead.
     *
     * @since 3.16.0
     */
    public class AnnotatedTextEdit : TextEdit {
        /**
         * The actual annotation identifier.
         */
        public string annotation_id { get; set; }

        public AnnotatedTextEdit (Range range, string new_text, string annotation_id) {
            base (range, new_text);
            this.annotation_id = annotation_id;
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
        public TextDocumentIdentifier text_document { get; private set; }

        /**
         * The edits to be applied.
         *
         * Support for AnnotatedTextEdit is guarded by the client capability
         * `workspace.workspaceEdit.changeAnnotationSupport`
         */
        public Array<TextEdit> edits { get; private set; }

        public TextDocumentEdit (TextDocumentIdentifier text_document, params TextEdit[] edits) {
            this.text_document = text_document;
            this.edits = new Array<TextEdit> ();

            foreach (var edit in edits)
                this.edits.append_val (edit);
        }
    }
}
