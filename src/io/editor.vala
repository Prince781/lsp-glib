/* editor.vala
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

/**
 * A JSON-RPC server implementing the editor's (client's) side of the Language
 * Server Protocol using {@link GLib.MainLoop}.
 */
public abstract class Lsp.Editor : Jsonrpc.Server {
    MainLoop loop;

    /**
     * Whether we've exited the server.
     */
    bool exited;

    public Cancellable cancellable { get; private set; default = new Cancellable (); }

    protected Editor (MainLoop loop) {
        this.loop = loop;
        this.notification.connect (notification_async);
        this.handle_call.connect ((client, method, id, parameters) => {
            handle_call_async.begin (client, method, id, parameters);
            return !exited;
        });
    }

    private async void notification_async (Jsonrpc.Client client, string method, Variant parameters) {
        if (exited)
            return;
    }

    private async void handle_call_async (Jsonrpc.Client client, string method, Variant id, Variant parameters) {
        if (exited)
            return;
    }

    /**
     * Sends the `initialize` request to the language server.
     * 
     * @see Lsp.Server.initialize_async
     */
    protected abstract async InitializeParams send_initialize_async () throws Error;
}
