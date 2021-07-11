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
    public class Command {
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

        public Command (string title, string command, params Variant[]? arguments = null) {
            this.title = title;
            this.command = command;
            this.arguments = arguments;
        }
    }
}
