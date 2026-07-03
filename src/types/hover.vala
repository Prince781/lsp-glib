/* hover.vala
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
     * The result of a hover request.
     */
    [Compact (opaque = true)]
    [CCode (ref_function = "lsp_hover_ref", unref_function = "lsp_hover_unref")]
    public class Hover {
        private int ref_count = 1;

        public unowned Hover ref () {
            AtomicInt.add (ref this.ref_count, 1);
            return this;
        }

        public void unref () {
            if (AtomicInt.dec_and_test (ref this.ref_count))
                this.free ();
        }

        private extern void free ();

        /**
         * The hover's contents as a markup content.
         *
         * Use a plain text {@link MarkupContent} for simple strings.
         */
        public MarkupContent contents { get; set; }

        /**
         * An optional range that is a range inside the document
         * that is used to visualize the hover, e.g. by changing the
         * background color.
         */
        public Range? range { get; set; }

        public Hover (MarkupContent contents, Range? range = null) {
            this.contents = contents;
            this.range = range;
        }

        public Hover.from_variant (Variant dict) throws DeserializeError {
            Variant? prop = null;

            prop = expect_property (dict, "contents", VariantType.ANY, "Hover");
            if (prop.is_of_type (VariantType.STRING))
                contents = new MarkupContent (MarkupKind.PLAINTEXT, (string) prop);
            else if (prop.is_of_type (VariantType.VARDICT))
                contents = new MarkupContent (
                    (MarkupKind) (int64) expect_property (prop, "kind", VariantType.INT64, "MarkupContent"),
                    (string) expect_property (prop, "value", VariantType.STRING, "MarkupContent")
                );
            else
                throw new DeserializeError.INVALID_TYPE ("expected string or MarkupContent for Hover.contents");

            if ((prop = lookup_property (dict, "range", VariantType.VARDICT, "Hover")) != null)
                range = Range.from_variant (prop);
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            if (contents.kind == MarkupKind.PLAINTEXT)
                dict.insert_value ("contents", contents.value);
            else {
                var doc = new VariantDict ();
                doc.insert_value ("kind", contents.kind.to_string ());
                doc.insert_value ("value", contents.value);
                dict.insert_value ("contents", doc.end ());
            }

            if (range != null)
                dict.insert_value ("range", range.to_variant ());

            return dict.end ();
        }
    }
}
