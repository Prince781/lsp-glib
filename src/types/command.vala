/* command.vala
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
     * Represents a reference to a command.
     * 
     * Provides a title which will be used to represent a command in the UI.
     * Commands are identified by a string identifier. The recommended way to
     * handle commands is to implement their execution on the server side if
     * the client and server provides the corresponding capabilities.
     * Alternatively the tool extension code could handle the command. The
     * protocol currently doesn’t specify a set of well-known commands.
     */
    public struct Command {
        /**
         * Title of the command, like `save`.
         */
        public string title { get; set; }

        /**
         * The identifier of the actual command handler.
         */
        public string command { get; set; }

        /**
         * Arguments that the command handler should be invoked with.
         */
        public Variant[]? arguments { get; set; }

        public Command (string title, string command, Variant[]? arguments = null) {
            this.title = title;
            this.command = command;
            this.arguments = arguments;
        }
    }
}
