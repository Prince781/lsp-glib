import Lsp from 'gi://Lsp?version=3.0';

const assertEqual = (actual, expected, message) => {
    if (actual !== expected)
        throw new Error(`${message}: expected ${expected}, got ${actual}`);
};

// Position is a stack-style record in C and is exposed as a compact boxed
// value in GJS. Exercise both its fields and its manual variant codec.
const position = new Lsp.Position();
position.init(12, 7);

const decoded = new Lsp.Position();
decoded.init_from_variant(position.to_variant());

assertEqual(decoded.line, 12, 'line did not round-trip');
assertEqual(decoded.character, 7, 'character did not round-trip');
