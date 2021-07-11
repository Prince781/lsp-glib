namespace Lsp {
    /**
     * Used when showing a message in the editor.
     *
     * @see Lsp.Client.show_message_async
     * @see Lsp.Client.ask_message_async
     */
    public enum MessageType {
        /**
         * Unknown message type. (Non-standard)
         */
        UNKNOWN = 0,
        ERROR   = 1,
        WARNING = 2,
        INFO    = 3,
        LOG     = 4
    }

    /**
     * Used to show an action in a prompt in the editor.
     *
     * @see Lsp.Client.ask_message_async
     */
    public struct MessageActionItem {
        /**
         * A short title like 'Retry', 'Open Log', etc.
         */
        public string title { get; set; }

        public MessageActionItem (string title) {
            this.title = title;
        }

        public MessageActionItem.from_variant (Variant dict) throws DeserializeError {
            Variant? prop = null;

            if ((prop = dict.lookup_value ("title", VariantType.STRING)) != null)
                this.title = (string)prop;
            else
                throw new DeserializeError.MISSING_PROPERTY ("property `title` not found for MessageActionItem");
        }

        public Variant to_variant () {
            var dict = new VariantDict ();
            dict.insert_value ("title", title);
            return dict.end ();
        }
    }
}
