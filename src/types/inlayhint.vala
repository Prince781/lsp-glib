/* inlayhint.vala
 *
 * Copyright 2022 Princeton Ferro <princetonferro@gmail.com>
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
     * The inlay hint kinds.
     *
     * @since 3.17.0
     */
    public enum InlayHintKind {
        TYPE = 1,
        PARAMETER = 2;
    }

    /**
     * A part of an inlay hint label.
     *
     * @since 3.17.0
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_inlay_hint_label_part_ref", unref_function = "lsp_inlay_hint_label_part_unref")]
    public class InlayHintLabelPart {
        private int ref_count = 1;

        public unowned InlayHintLabelPart ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * The value of this label part.
         */
        public string value { get; set; }

        /**
         * The tooltip text when hovering over this label part.
         */
        public MarkupContent? tooltip { get; set; }

        /**
         * An optional location for this label part.
         */
        public Location? location { get; set; }

        /**
         * An optional command for this label part.
         */
        public Command? command { get; set; }

        public InlayHintLabelPart (string value) {
            this.value = value;
        }

        public InlayHintLabelPart.from_variant (Variant dict) throws DeserializeError, UriError {
            Variant? prop = null;

            value = (string) expect_property (dict, "value", VariantType.STRING, "InlayHintLabelPart");

            if ((prop = lookup_property (dict, "tooltip", VariantType.ANY, "InlayHintLabelPart")) != null) {
                if (prop.is_of_type (VariantType.STRING))
                    tooltip = new MarkupContent (MarkupKind.PLAINTEXT, (string) prop);
                else if (prop.is_of_type (VariantType.VARDICT))
                    tooltip = new MarkupContent (
                        (MarkupKind) (int64) expect_property (prop, "kind", VariantType.INT64, "MarkupContent"),
                        (string) expect_property (prop, "value", VariantType.STRING, "MarkupContent")
                    );
                else
                    throw new DeserializeError.INVALID_TYPE ("InlayHintLabelPart.tooltip must be a string or a MarkupContent");
            }

            if ((prop = lookup_property (dict, "location", VariantType.VARDICT, "InlayHintLabelPart")) != null)
                location = Location.from_variant (prop);

            if ((prop = lookup_property (dict, "command", VariantType.VARDICT, "InlayHintLabelPart")) != null)
                command = new Command.from_variant (prop);
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            dict.insert_value ("value", new Variant.string (value));
            if (tooltip != null) {
                if (tooltip.kind == MarkupKind.PLAINTEXT)
                    dict.insert_value ("tooltip", tooltip.value);
                else {
                    var doc = new VariantDict ();
                    doc.insert_value ("kind", tooltip.kind.to_string ());
                    doc.insert_value ("value", tooltip.value);
                    dict.insert_value ("tooltip", doc.end ());
                }
            }
            if (location != null)
                dict.insert_value ("location", location.to_variant ());
            if (command != null)
                dict.insert_value ("command", command.to_variant ());
            return dict.end ();
        }
    }

    /**
     * An inlay hint is a visual decoration that appears inline with the
     * text, e.g. to show the type of a variable or the name of a parameter.
     *
     * @since 3.17.0
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_inlay_hint_ref", unref_function = "lsp_inlay_hint_unref")]
    public class InlayHint {
        private int ref_count = 1;

        public unowned InlayHint ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * The position of this hint.
         */
        public Position position { get; set; }

        /**
         * The label of this hint. A human-readable string or an array of
         * {@link InlayHintLabelPart} label parts.
         */
        public Variant label { get; set; }

        /**
         * The kind of this hint.
         */
        public InlayHintKind kind { get; set; default = TYPE; }

        /**
         * Optional text edits to perform when this inlay hint is
         * accepted.
         */
        public TextEdit[]? text_edits { get; set; }

        /**
         * The tooltip text when hovering over this hint.
         */
        public MarkupContent? tooltip { get; set; }

        /**
         * Whether this hint should be shown with padding to the left.
         */
        public bool padding_left { get; set; }

        /**
         * Whether this hint should be shown with padding to the right.
         */
        public bool padding_right { get; set; }

        /**
         * A data entry field that is preserved between an inlay hint
         * and an inlay hint resolve request.
         */
        public Variant? data { get; set; }

        public InlayHint (Position position, Variant label, InlayHintKind kind = TYPE) {
            this.position = position;
            this.label = label;
            this.kind = kind;
        }

        public InlayHint.from_variant (Variant dict) throws DeserializeError, UriError {
            Variant? prop = null;

            position = Position.from_variant (expect_property (dict, "position", VariantType.VARDICT, "InlayHint"));
            label = expect_property (dict, "label", VariantType.ANY, "InlayHint");

            if ((prop = lookup_property (dict, "kind", VariantType.INT64, "InlayHint")) != null)
                kind = (InlayHintKind) (int64) prop;

            if ((prop = lookup_property (dict, "textEdits", VariantType.ARRAY, "InlayHint")) != null) {
                TextEdit[] edits = {};
                foreach (var edit in prop)
                    edits += TextEdit.from_variant (edit);
                text_edits = edits;
            }

            if ((prop = lookup_property (dict, "tooltip", VariantType.ANY, "InlayHint")) != null) {
                if (prop.is_of_type (VariantType.STRING))
                    tooltip = new MarkupContent (MarkupKind.PLAINTEXT, (string) prop);
                else if (prop.is_of_type (VariantType.VARDICT))
                    tooltip = new MarkupContent (
                        (MarkupKind) (int64) expect_property (prop, "kind", VariantType.INT64, "MarkupContent"),
                        (string) expect_property (prop, "value", VariantType.STRING, "MarkupContent")
                    );
                else
                    throw new DeserializeError.INVALID_TYPE ("InlayHint.tooltip must be a string or a MarkupContent");
            }

            if ((prop = lookup_property (dict, "paddingLeft", VariantType.BOOLEAN, "InlayHint")) != null)
                padding_left = (bool) prop;

            if ((prop = lookup_property (dict, "paddingRight", VariantType.BOOLEAN, "InlayHint")) != null)
                padding_right = (bool) prop;

            if ((prop = lookup_property (dict, "data", VariantType.VARIANT, "InlayHint")) != null)
                data = prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            dict.insert_value ("position", position.to_variant ());
            dict.insert_value ("label", label);
            if (kind != TYPE)
                dict.insert_value ("kind", new Variant.int64 (kind));
            if (text_edits != null) {
                Variant[] edit_list = {};
                foreach (var edit in text_edits)
                    edit_list += edit.to_variant ();
                dict.insert_value ("textEdits", edit_list);
            }
            if (tooltip != null) {
                if (tooltip.kind == MarkupKind.PLAINTEXT)
                    dict.insert_value ("tooltip", tooltip.value);
                else {
                    var doc = new VariantDict ();
                    doc.insert_value ("kind", tooltip.kind.to_string ());
                    doc.insert_value ("value", tooltip.value);
                    dict.insert_value ("tooltip", doc.end ());
                }
            }
            if (padding_left)
                dict.insert_value ("paddingLeft", new Variant.boolean (true));
            if (padding_right)
                dict.insert_value ("paddingRight", new Variant.boolean (true));
            if (data != null)
                dict.insert_value ("data", data);
            return dict.end ();
        }
    }

    /**
     * The parameters of a {@link textDocument/inlayHint} request.
     *
     * @since 3.17.0
     */
    public class InlayHintParams {
        /**
         * The document to fetch inlay hints for.
         */
        public TextDocumentIdentifier text_document { get; set; }

        /**
         * The range to fetch inlay hints for.
         */
        public Range range { get; set; }

        public InlayHintParams (TextDocumentIdentifier text_document, Range range) {
            this.text_document = text_document;
            this.range = range;
        }

        public InlayHintParams.from_variant (Variant dict) throws DeserializeError, UriError {
            text_document = TextDocumentIdentifier.from_variant (expect_property (dict, "textDocument", VariantType.VARDICT, "InlayHintParams"));
            range = Range.from_variant (expect_property (dict, "range", VariantType.VARDICT, "InlayHintParams"));
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            dict.insert_value ("textDocument", text_document.to_variant ());
            dict.insert_value ("range", range.to_variant ());
            return dict.end ();
        }
    }

    /**
     * Options for inlay hint support.
     *
     * @since 3.17.0
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_inlay_hint_options_ref", unref_function = "lsp_inlay_hint_options_unref")]
    public class InlayHintOptions {
        private int ref_count = 1;

        public unowned InlayHintOptions ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * Whether the server supports resolving additional information
         * for an inlay hint.
         */
        public bool resolve_provider { get; set; }

        public InlayHintOptions (bool resolve_provider = false) {
            this.resolve_provider = resolve_provider;
        }

        public InlayHintOptions.from_variant (Variant variant) throws DeserializeError {
            Variant? prop = lookup_property (variant, "resolveProvider", VariantType.BOOLEAN, "InlayHintOptions");
            if (prop != null)
                resolve_provider = (bool) prop;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            if (resolve_provider)
                dict.insert_value ("resolveProvider", new Variant.boolean (true));
            return dict.end ();
        }
    }
}
