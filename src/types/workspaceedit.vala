/* workspaceedit.vala
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
     * An operation to edit a workspace.
     *
     * @see WorkspaceEdit.changes
     */
    public abstract class ResourceOperation {
        public abstract unowned string kind { get; }

        public abstract Variant to_variant ();
    }

    /**
     * Create file operation
     */
    public class CreateFile : ResourceOperation {
        public override unowned string kind {
            get { return ResourceOperationKind.CREATE.to_string (); }
        }

        /**
         * The resource to create.
         */
        public Uri uri { get; set; }

        [Flags]
        public enum Options {
            NONE,
            OVERWRITE,
            IGNORE_IF_EXISTS;

            public static Options from_variant (Variant variant) throws DeserializeError {
                var options = NONE;
                Variant? prop = null;
                if ((prop = lookup_property (variant, "overwrite", VariantType.BOOLEAN, "LspCreateFileOptions")) != null && (bool)prop)
                    options |= OVERWRITE;
                if ((prop = lookup_property (variant, "ignoreIfExists", VariantType.BOOLEAN, "LspCreateFileOptions")) != null && (bool)prop)
                    options |= IGNORE_IF_EXISTS;
                return options;
            }
        }

        public Options options { get; set; }

        public string? annotation_id { get; set; }

        public CreateFile.from_variant (Variant variant) throws DeserializeError, UriError {
            uri = Uri.parse ((string) expect_property (variant, "uri", VariantType.STRING, "LspCreateFile"), UriFlags.NONE);
            Variant? prop = null;
            if ((prop = lookup_property (variant, "options", VariantType.VARDICT, "LspCreateFileOptions")) != null)
                options = Options.from_variant (prop);
            annotation_id = (string?) lookup_property (variant, "annotationId", VariantType.STRING, "LspCreateFile");
        }

        public override Variant to_variant () {
            var variant = new VariantDict ();

            variant.insert_value ("kind", kind);
            variant.insert_value ("uri", uri.to_string ());
            variant.insert_value ("options", options);
            if (annotation_id != null)
                variant.insert_value ("annotationId", annotation_id);

            return variant.end ();
        }
    }

    /**
     * Rename file operation
     */
    public class RenameFile : ResourceOperation {
        public override unowned string kind {
            get { return ResourceOperationKind.RENAME.to_string (); }
        }

        public Uri old_uri { get; set; }

        public Uri new_uri { get; set; }

        [Flags]
        public enum Options {
            NONE,
            OVERWRITE,
            IGNORE_IF_EXISTS;

            public static Options from_variant (Variant variant) throws DeserializeError {
                var options = NONE;
                Variant? prop = null;
                if ((prop = lookup_property (variant, "overwrite", VariantType.BOOLEAN, "LspRenameFileOptions")) != null && (bool)prop)
                    options |= OVERWRITE;
                if ((prop = lookup_property (variant, "ignoreIfExists", VariantType.BOOLEAN, "LspRenameFileOptions")) != null && (bool)prop)
                    options |= IGNORE_IF_EXISTS;
                return options;
            }
        }

        public Options options { get; set; }

        public string? annotation_id { get; set; }

        public RenameFile.from_variant (Variant variant) throws DeserializeError, UriError {
            old_uri = Uri.parse ((string) expect_property (variant, "oldUri", VariantType.STRING, "LspRenameFile"), UriFlags.NONE);
            new_uri = Uri.parse ((string) expect_property (variant, "newUri", VariantType.STRING, "LspRenameFile"), UriFlags.NONE);
            Variant? prop = null;
            if ((prop = lookup_property (variant, "options", VariantType.VARDICT, "LspRenameFileOptions")) != null)
                options = Options.from_variant (prop);
            annotation_id = (string?) lookup_property (variant, "annotationId", VariantType.STRING, "LspRenameFile");
        }

        public override Variant to_variant () {
            var variant = new VariantDict ();

            variant.insert_value ("kind", kind);
            variant.insert_value ("oldUri", old_uri.to_string ());
            variant.insert_value ("newUri", new_uri.to_string ());
            variant.insert_value ("options", options);
            if (annotation_id != null)
                variant.insert_value ("annotationId", annotation_id);

            return variant.end ();
        }
    }

    /**
     * Delete file operation
     */
    public class DeleteFile : ResourceOperation {
        public override unowned string kind {
            get { return ResourceOperationKind.DELETE.to_string (); }
        }

        public Uri uri { get; set; }

        [Flags]
        public enum Options {
            NONE,
            RECURSIVE,
            IGNORE_IF_NOT_EXISTS;

            public static Options from_variant (Variant variant) throws DeserializeError {
                var options = NONE;
                Variant? prop = null;
                if ((prop = lookup_property (variant, "recursive", VariantType.BOOLEAN, "LspDeleteFileOptions")) != null && (bool)prop)
                    options |= RECURSIVE;
                if ((prop = lookup_property (variant, "ignoreIfNotExists", VariantType.BOOLEAN, "LspDeleteFileOptions")) != null && (bool)prop)
                    options |= IGNORE_IF_NOT_EXISTS;
                return options;
            }
        }

        public Options options { get; set; }

        public string? annotation_id { get; set; }

        public DeleteFile.from_variant (Variant variant) throws DeserializeError, UriError {
            uri = Uri.parse ((string) expect_property (variant, "uri", VariantType.STRING, "LspDeleteFile"), UriFlags.NONE);
            Variant? prop = null;
            if ((prop = lookup_property (variant, "options", VariantType.VARDICT, "LspDeleteFileOptions")) != null)
                options = Options.from_variant (prop);
            annotation_id = (string?) lookup_property (variant, "annotationId", VariantType.STRING, "LspDeleteFile");
        }

        public override Variant to_variant () {
            var variant = new VariantDict ();

            variant.insert_value ("kind", kind);
            variant.insert_value ("uri", uri.to_string ());
            variant.insert_value ("options", options);
            if (annotation_id != null)
                variant.insert_value ("annotationId", annotation_id);

            return variant.end ();
        }
    }

    /**
     * A workspace edit represents changes to many resources managed in the
     * workspace.
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_workspace_edit_ref", unref_function = "lsp_workspace_edit_unref")]
    public class WorkspaceEdit {
        private int ref_count = 1;

        public unowned WorkspaceEdit ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * Holds changes to existing resources.
         *
         * This corresponds to the `documentChanges` property in the protocol.
         */
        public ResourceOperation[] changes { get; private set; default = {}; }

        /**
         * A map of change annotations that can be referenced in
         * annotated {@link TextEdit}s or create, rename and delete file / folder
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

        /**
         * Deserialize this from a {@link GLib.Variant}
         */
        public WorkspaceEdit.from_variant (Variant variant) throws DeserializeError, UriError {
            ResourceOperation[] document_changes = {};
            foreach (var vchange in lookup_property (variant, "documentChanges", VariantType.ARRAY, "LspWorkspaceEdit")) {
                var prop = (string?) lookup_property (vchange, "kind", VariantType.STRING, "LspWorkspaceEdit");
                if (prop == null)
                    document_changes += new TextDocumentEdit.from_variant (vchange);
                else if (prop == "create")
                    document_changes += new CreateFile.from_variant (vchange);
                else if (prop == "delete")
                    document_changes += new DeleteFile.from_variant (vchange);
                else if (prop == "rename")
                    document_changes += new RenameFile.from_variant (vchange);
                else
                    throw new DeserializeError.UNEXPECTED_ELEMENT ("unexpected element in documentChanges array");
            }
        }

        /**
         * Serialize this to a {@link GLib.Variant}
         */
        public Variant to_variant () {
            var variant = new VariantDict ();

            Variant[] changes_list = {};
            foreach (var change in changes)
                changes_list += change.to_variant ();
            variant.insert_value ("changes", changes_list);
            if (change_annotations != null) {
                var annotations_dict = new VariantDict ();
                foreach (unowned var key in change_annotations.get_keys ())
                    annotations_dict.insert_value (key, change_annotations[key].to_variant ());
                variant.insert_value ("changeAnnotations", annotations_dict.end ());
            }

            return variant.end ();
        }
    }
}