/* initialization.vala
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
     * Information about the client/editor.
     *
     * @since 3.15.0
     */
    [Compact]
    public class ClientInfo {
        public string name;
        public string? version;

        public ClientInfo (string name, string? version = null) {
            this.name = name;
            this.version = version;
        }
    }

    /**
     * Sent from the client / editor to the server.
     */
    public class InitializeParams {
        public int64 process_id { get; private set; }

        /**
         * (Kept for backwards compatibility)
         *
         * The rootPath of the workspace. Is null if no folder is open.
         *
         * @deprecated in favor of `rootUri`.
         */
        string root_path;

        /**
         * (Kept for backwards compatibility)
         *
         * The rootUri of the workspace. Is null if no folder is open. If both
         * `rootPath` and `rootUri` are set `rootUri` wins.
         *
         * @deprecated in favor of `workspaceFolders`
         */
        Uri root_uri;

        public ClientInfo? client_info { get; owned set; }

        public WorkspaceFolder[] workspaces { get; private set; }

        public InitializeParams (WorkspaceFolder primary_workspace,
                                 params WorkspaceFolder[] secondary_workspaces) throws ConvertError {
            WorkspaceFolder[] temp_workspaces = {};

            root_uri = primary_workspace.uri;

            string root_uri_string = uri_to_string (primary_workspace.uri);

            root_path = Filename.from_uri (root_uri_string, null);

            temp_workspaces += primary_workspace;
            foreach (var secondary_workspace in secondary_workspaces)
                temp_workspaces += secondary_workspace;
            workspaces = temp_workspaces;
        }

        public InitializeParams.from_variant (Variant dict) throws DeserializeError {
            Variant? prop = null;

            if ((prop = dict.lookup_value ("processId", VariantType.INT64)) != null)
                process_id = (int64)prop;
            else
                throw new DeserializeError.MISSING_PROPERTY ("property `processId` not found for InitializeParams");

            if ((prop = dict.lookup_value ("clientInfo", VariantType.VARDICT)) != null) {
                Variant? inside_prop = null;
                string? client_name = null;
                string? client_version = null;

                if ((inside_prop = prop.lookup_value ("name", VariantType.STRING)) != null)
                    client_name = (string)inside_prop;
                if ((inside_prop = prop.lookup_value ("version", VariantType.STRING)) != null)
                    client_version = (string)inside_prop;

                if (client_name != null)
                    client_info = new ClientInfo (client_name, client_version);
            }

            WorkspaceFolder[] temp_workspaces = {};
            string? client_root_path = null;
            string? client_root_uri = null;

            if ((prop = dict.lookup_value ("rootPath", VariantType.STRING)) != null)
                client_root_path = (string)prop;

            if ((prop = dict.lookup_value ("rootUri", VariantType.STRING)) != null)
                client_root_uri = (string)prop;
            else
                throw new DeserializeError.MISSING_PROPERTY ("property `rootUri` not found for InitializeParams");

            workspaces = temp_workspaces;
        }
    }

    /**
     * Information about the server.
     *
     * @since 3.15.0
     */
    [Compact]
    public class ServerInfo {
        public string name;
        public string? version;

        public ServerInfo (string name, string? version = null) {
            this.name = name;
            this.version = version;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("name", name);
            if (version != null)
                dict.insert_value ("version", version);

            return dict.end ();
        }
    }

    /**
     * Sent from the language server to the client / editor after
     * initialization.
     */
    public class InitializeResult {
        /**
         * The capabilities the language server provides.
         */
        public ServerCaps capabilities { get; owned set; }

        public ServerInfo? server_info { get; owned set; }

        public InitializeResult (ServerCaps capabilities) {
            this.capabilities = capabilities;
        }

        public Variant to_variant () {
            var dict = new VariantDict ();

            dict.insert_value ("capabilities", capabilities.to_variant ());
            if (server_info != null)
                dict.insert_value ("serverInfo", server_info.to_variant ());

            return dict.end ();
        }
    }
}
