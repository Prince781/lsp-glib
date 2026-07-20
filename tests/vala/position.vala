using Lsp;

/*
 * Position is embedded in most document requests. These tests cover the
 * library's native unsigned representation and the signed integer variants
 * produced when JSON numbers pass through jsonrpc-glib.
 */

private Position deserialize_position (Variant variant) {
    try {
        return Position.from_variant (variant);
    } catch (DeserializeError e) {
        error ("position deserialization failed: %s", e.message);
    }
}

private void test_round_trip () {
    var original = Position (3, 4);
    var decoded = deserialize_position (original.to_variant ());

    assert (decoded.line == original.line);
    assert (decoded.character == original.character);
}

private void test_signed_json_values () {
    var dict = new VariantDict ();
    dict.insert_value ("line", new Variant.int64 (8));
    dict.insert_value ("character", new Variant.int64 (20));

    var decoded = deserialize_position (dict.end ());
    assert (decoded.line == 8);
    assert (decoded.character == 20);
}

private void test_missing_property () {
    var dict = new VariantDict ();
    dict.insert_value ("line", new Variant.uint64 (3));

    bool caught = false;
    try {
        Position.from_variant (dict.end ());
    } catch (DeserializeError.MISSING_PROPERTY e) {
        caught = true;
    } catch (DeserializeError e) {
        assert_not_reached ();
    }
    assert (caught);
}

private void test_negative_value () {
    var dict = new VariantDict ();
    dict.insert_value ("line", new Variant.int64 (-1));
    dict.insert_value ("character", new Variant.int64 (0));

    bool caught = false;
    try {
        Position.from_variant (dict.end ());
    } catch (DeserializeError.INVALID_TYPE e) {
        caught = true;
    } catch (DeserializeError e) {
        assert_not_reached ();
    }
    assert (caught);
}

private int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/serialization/position/round-trip", test_round_trip);
    Test.add_func ("/deserialization/position/signed-json-values", test_signed_json_values);
    Test.add_func ("/deserialization/position/missing-property", test_missing_property);
    Test.add_func ("/deserialization/position/negative-value", test_negative_value);
    return Test.run ();
}
