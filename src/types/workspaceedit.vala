namespace Lsp {
    public interface ResourceOperation {
        public string kind {
            get {
                if (this is TextDocumentEdit)
                    return "textDocumentEdit";
                if (this is CreateFile)
                    return ResourceOperationKind.CREATE;
                if (this is RenameFile)
                    return ResourceOperationKind.RENAME;
                if (this is DeleteFile)
                    return ResourceOperationKind.DELETE;
                return "unknown";
            }
        }
    }

    /**
     * Create file operation
     */
    public class CreateFile : ResourceOperation {
        /**
         * The resource to create.
         */
        public Uri uri;

        [Flags]
        public enum Options {
            NONE,
            OVERWRITE
        }

        public Options options;

        public string? annotation_id;
    }

    /**
     * Rename file operation
     */
    public class RenameFile : ResourceOperation {
        public Uri old_uri;

        public Uri new_uri;

        [Flags]
        public enum Options {
            NONE,
            OVERWRITE
        }

        public Options options;

        public string? annotation_id;
    }

    /**
     * Delete file operation
     */
    public class DeleteFile : ResourceOperation {
        public Uri uri;

        [Flags]
        public enum Options {
            NONE,
            RECURSIVE,
            IGNORE_IF_NOT_EXISTS
        }

        public Options options;

        public string? annotation_id;
    }

    /**
     * A workspace edit represents changes to many resources managed in the
     * workspace.
     */
    public class WorkspaceEdit {
        /**
         * Holds changes to existing resources.
         *
         * This corresponds to the `documentChanges` property in the protocol.
         */
        public Array<ResourceOperation> changes { get; private set; }

        /**
         * A map of change annotations that can be referenced in
         * {@link AnnotatedTextEdit}s or create, rename and delete file / folder
         * operations.
         *
         * Each key is the change annotation identifier.
         *
         * Whether clients honor this property depends on the client capability
         * `workspace.changeAnnotationSupport`.
         *
         * @since 3.16.0
         */
        public HashTable<string, ChangeAnnotation>? change_annotations { get; private set; }
    }
}
