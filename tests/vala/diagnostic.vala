using Lsp;

void main() {
    Position[] pos = {Position(1, 2), Position(3, 4)};

    var range = Range(pos[0], pos[1]);
    var diag = new Diagnostic("diagnostic message", range);

    print("diag = %s\n", diag.to_variant().print(true));
}
