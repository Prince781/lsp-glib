/* library.vala
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
     * Convenience function to convert a URI to a string.
     */
    public static string uri_to_string (Uri uri) {
        return Uri.join (UriFlags.NONE,
                         uri.get_scheme (),
                         uri.get_userinfo (),
                         uri.get_host (),
                         uri.get_port (),
                         uri.get_path (),
                         uri.get_query (),
                         uri.get_fragment ());
    }

    /**
     * Expect a property on a variant.
     */
    public static Variant expect_property (Variant dict, string property_name,
                                           VariantType expected_type,
                                           string parent_type_name) throws DeserializeError {
        if (!dict.is_of_type (VariantType.DICTIONARY))
            throw new DeserializeError.INVALID_TYPE ("expected dictionary for %s", parent_type_name);
        var prop = dict.lookup_value (property_name, expected_type);
        if (prop == null)
            throw new DeserializeError.MISSING_PROPERTY ("missing property `%s` for %s", property_name, parent_type_name);
        return prop;
    }

    public static Variant? lookup_property (Variant dict, string property_name,
                                            VariantType expected_type,
                                            string parent_type_name) throws DeserializeError {
        if (!dict.is_of_type (VariantType.DICTIONARY))
            throw new DeserializeError.INVALID_TYPE ("expected dictionary for %s", parent_type_name);
        return dict.lookup_value (property_name, expected_type);
    }
}
