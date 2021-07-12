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
