namespace Lsp {
    /**
     * Problems encountered during deserialization.
     */
    public errordomain DeserializeError {
        /**
         * A required property was missing.
         */
        MISSING_PROPERTY,

        /**
         * A property had an invalid type.
         */
        INVALID_TYPE
    }
}
