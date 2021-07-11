namespace Lsp {
    public enum MarkupKind {
        PLAINTEXT,
        MARKDOWN;

        public unowned string to_string () {
            switch (this) {
                case PLAINTEXT:
                    return "plaintext";
                case MARKDOWN:
                    return "markdown";
            }

            assert_not_reached ();
        }
    }

    /**
     * A `MarkupContent` literal represents a string value which content is
     * interpreted based on its kind flag.
     *
     * Currently the protocol supports `plaintext` and `markdown` as markup kinds.
     *
     * If the kind is `markdown` then the value can contain fenced code blocks like
     * in GitHub issues.
     *
     * Here is an example how such a string can be constructed in Vala:
     * {{{
     * var markdown = new MarkupContent (
     *  MarkupKind.MARKDOWN,
     *  "# Header\n" + "Some text\n" + "```vala\n" + "someCode();\n" + "```"
     * );
     * }}}
     *
     * ''Please Note'' that clients might sanitize the return markdown. A client could
     * decide to remove HTML from the markdown to avoid script execution.
     */
    public class MarkupContent {
        /**
         * The type of the markup
         */
        public MarkupKind kind { get; set; }

        /**
         * The content itself
         */
        public string value { get; set; }

        public MarkupContent (MarkupKind kind, string value) {
            this.kind = kind;
            this.value = value;
        }
    }
}
