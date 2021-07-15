using Lsp;

void main(string[] args) {
    var pos = Position (3, 4);

    print("%s\n", pos.to_variant().print_string(null, true).str);
}
