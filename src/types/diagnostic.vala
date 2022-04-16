/* diagnostic.vala
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
     * Structure to capture a description for an error code.
     *
     * @since 3.16.0
     */
    [Compact (opaque = true)]
    public class CodeDescription {
        /**
         * An URI to open with more information about the diagnostic error.
         */
        public string href { get; set; }

        public CodeDescription (string href) {
            this.href = href;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            dict.insert_value ("href", href);
            return dict.end ();
        }
    }

    /**
     * The diagnostic severity
     */
    public enum DiagnosticSeverity {
        UNSET       = 0,
        ERROR       = 1,
        WARNING     = 2,
        INFORMATION = 3,
        HINT        = 4
    }

    /**
     * The diagnostic tags
     *
     * @since 3.15.0
     */
    public enum DiagnosticTag {
        UNSET       = 0,

        /**
         * Unused or unnecessary code.
         *
         * Clients are allowed to render diagnostics with this tag faded out
         * instead of having an error squiggle.
         */
        UNNECESSARY = 1,

        /**
         * Deprecated or obsolete code.
         *
         * Clients are allowed to render diagnostics with this tag strike
         * through.
         */
        DEPRECATED  = 2;

        public static DiagnosticTag parse_int (int value) throws DeserializeError {
            if (value == UNSET || value == UNNECESSARY || value == DEPRECATED)
                return value;
            throw new DeserializeError.INVALID_TYPE ("%d is not a %s", value, typeof (DiagnosticTag).name ());
        }
    }

    /**
     * Represents a related message and source code location for a diagnostic.
     *
     * This should be used to point to code locations that cause or are related
     * to a diagnostics, e.g when duplicating a symbol in a scope.
     */
    public struct DiagnosticRelatedInformation {
        /**
         * The location of this related diagnostic information.
         */
        public Location location { get; set; }

        /**
         * The message of this related diagnostic information.
         */
        public string message { get; set; }

        public DiagnosticRelatedInformation (Location location, string message) {
            this.location = location;
            this.message = message;
        }

        public DiagnosticRelatedInformation.from_variant (Variant variant) throws UriError, DeserializeError {
            location = Location.from_variant (expect_property (variant, "location", VariantType.VARIANT, typeof (DiagnosticRelatedInformation).name ()));
            message = (string) expect_property (variant, "message", VariantType.STRING, typeof (DiagnosticRelatedInformation).name ());
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            dict.insert_value ("location", location.to_variant ());
            dict.insert_value ("message", message);
            return dict.end ();
        }
    }

    /**
     * Represents a diagnostic, such as a compiler error or warning.
     *
     * Diagnostic objects are only valid in the scope of a resource.
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_diagnostic_ref", unref_function = "lsp_diagnostic_unref")]
    public class Diagnostic {
        private int ref_count = 1;

        public unowned Diagnostic ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * The range at which the message applies.
         */
        public Range range { get; set; }

        /**
         * The diagnostic's severity. Can be omitted. If omitted it is up to
         * the client to interpret diagnostics as error, warning, info or hint.
         */
        public DiagnosticSeverity severity { get; set; }

        /**
         * The diagnostic's code, which might appear in the user interface.
         */
        public string? code { get; set; }

        /**
         * An optional property to describe the error code.
         *
         * @since 3.16.0
         */
        public CodeDescription? code_description { get; owned set; }

        /**
         * A human-readable string describing the source of this diagnostic,
         * e.g. 'vala' or 'vala lint'.
         */
        public string? source { get; set; }

        /**
         * The diagnostic's message.
         */
        public string message { get; set; }

        /**
         * Additional metadata about the diagnostic.
         *
         * @since 3.15.0
         */
        public DiagnosticTag[]? tags { get; set; }

        /**
         * An array of related diagnostic information, e.g. when symbol-names
         * within a scope collide all definitions can be marked via this
         * property.
         */
        public DiagnosticRelatedInformation[]? related_information { get; set; }

        /**
         * A data entry field that is preserved between a
         * `textDocument/publishDiagnostics` notification and
         * `textDocument/codeAction` request.
         *
         * @since 3.16.0
         */
        public Variant? data { get; set; }

        public Diagnostic (string message, Range range) {
            this.message = message;
            this.range = range;
        }

        public Diagnostic.from_variant (Variant variant) throws DeserializeError, UriError {
            Variant? prop = null;

            range = Range.from_variant (expect_property (variant, "range", VariantType.VARIANT, "LspDiagnostic"));

            if ((prop = lookup_property (variant, "severity", VariantType.INT64, "LspDiagnostic")) != null)
                severity = (DiagnosticSeverity) prop;

            if ((prop = lookup_property (variant, "code", VariantType.INT64, "LspDiagnostic")) != null) {
                if (prop.is_of_type (VariantType.INT64))
                    code = ((int64) prop).to_string ();
                else if (prop.is_of_type (VariantType.STRING))
                    code = (string) prop;
                else
                    throw new DeserializeError.INVALID_TYPE ("LspDiagnostic.code must be an int64 or a string");
            }

            message = (string) expect_property (variant, "message", VariantType.STRING, "LspDiagnostic");

            if ((prop = lookup_property (variant, "tags", VariantType.ARRAY, "LspDiagnostic")) != null) {
                DiagnosticTag[] diag_tags = {};
                foreach (var tag in prop) {
                    if (!tag.is_of_type (VariantType.INT64))
                        throw new DeserializeError.INVALID_TYPE ("expected int64 element in LspDiagnostic.tags");
                    diag_tags += DiagnosticTag.parse_int ((int) (int64) tag);
                }
                tags = diag_tags;
            }

            if ((prop = lookup_property (variant, "relatedInformation", VariantType.ARRAY, "LspDiagnostic")) != null) {
                DiagnosticRelatedInformation[] related_info = {};
                foreach (var tag in prop) {
                    if (!tag.is_of_type (VariantType.INT64))
                        throw new DeserializeError.INVALID_TYPE ("expected DiagnosticRelatedInformation element in Diagnostic.relatedInformation");
                    related_info += DiagnosticRelatedInformation.from_variant (tag);
                }
                related_information = related_info;
            }
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("range", range.to_variant ());
            if (severity != DiagnosticSeverity.UNSET)
                dict.insert_value ("severity", severity);
            if (code != null)
                dict.insert_value ("code", code);
            if (code_description != null)
                dict.insert_value ("codeDescription", code_description.to_variant ());
            if (source != null)
                dict.insert_value ("source", source);
            dict.insert_value ("message", message);
            if (tags != null) {
                Variant[] tags_list = {};
                foreach (var tag in tags)
                    tags_list += tag;
                dict.insert_value ("tags", new Variant.array (VariantType.INT64, tags_list));
            }
            if (related_information != null) {
                Variant[] related_information_list = {};
                foreach (unowned var related in related_information)
                    related_information_list += related.to_variant ();
                dict.insert_value ("relatedInformation", related_information_list);
            }
            if (data != null)
                dict.insert_value ("data", data);

            return dict.end ();
        }
    }
}