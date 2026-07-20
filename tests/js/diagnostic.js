import GLib from 'gi://GLib';
import Lsp from 'gi://Lsp?version=3.0';

const assertEqual = (actual, expected, message) => {
    if (actual !== expected)
        throw new Error(`${message}: expected ${expected}, got ${actual}`);
};

const makePosition = (line, character) => {
    const position = new Lsp.Position();
    position.init(line, character);
    return position;
};

const range = new Lsp.Range();
range.init(makePosition(4, 2), makePosition(4, 11));

const diagnostic = Lsp.Diagnostic.new(
    'unused local',
    range,
);
diagnostic.set_severity(Lsp.DiagnosticSeverity.WARNING);
diagnostic.set_code('W001');
diagnostic.set_source('gjs-test');
diagnostic.set_tags([Lsp.DiagnosticTag.UNNECESSARY]);
diagnostic.set_data(new GLib.Variant('s', 'diagnostic-token'));

const decoded = Lsp.Diagnostic.from_variant(diagnostic.to_variant());
assertEqual(decoded.get_range().start.line, 4, 'range did not round-trip');
assertEqual(decoded.get_severity(), Lsp.DiagnosticSeverity.WARNING,
    'severity did not round-trip');
assertEqual(decoded.get_code(), 'W001', 'code did not round-trip');
assertEqual(decoded.get_source(), 'gjs-test', 'source did not round-trip');
assertEqual(decoded.get_tags()[0], Lsp.DiagnosticTag.UNNECESSARY,
    'tags did not round-trip');
assertEqual(decoded.get_data().deepUnpack(), 'diagnostic-token',
    'data did not round-trip');
