namespace Lsp {
    public class WorkspaceFolder {
        /**
         * The URI associated with the root of this workspace folder.
         */
        public Uri uri { get; set; }

        /**
         * The name of this workspace folder. Used to refer to this workspace
         * folder in the user interface.
         */
        public string name { get; set; }

        public WorkspaceFolder (Uri uri, string name) {
            this.uri = uri;
            this.name = name;
        }
    }
}
