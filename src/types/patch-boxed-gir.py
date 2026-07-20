#!/usr/bin/env python3

import re
import sys
import xml.etree.ElementTree as ElementTree
from pathlib import Path


CORE_NAMESPACE = "http://www.gtk.org/introspection/core/1.0"
C_NAMESPACE = "http://www.gtk.org/introspection/c/1.0"
DOC_NAMESPACE = "http://www.gtk.org/introspection/doc/1.0"
GLIB_NAMESPACE = "http://www.gtk.org/introspection/glib/1.0"

ElementTree.register_namespace("", CORE_NAMESPACE)
ElementTree.register_namespace("c", C_NAMESPACE)
ElementTree.register_namespace("doc", DOC_NAMESPACE)
ElementTree.register_namespace("glib", GLIB_NAMESPACE)


def read_boxed_types(path: Path) -> dict[str, str]:
    pattern = re.compile(r"LSP_BOXED_TYPE \((\w+), (\w+)\)")
    types = {}

    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.fullmatch(line)
        if match is None:
            raise ValueError(f"invalid boxed type declaration: {line}")
        c_type, symbol_prefix = match.groups()
        types[c_type] = symbol_prefix

    return types


def main() -> None:
    input_path, output_path, definitions_path = map(Path, sys.argv[1:])
    boxed_types = read_boxed_types(definitions_path)
    tree = ElementTree.parse(input_path)

    for record in tree.findall(f".//{{{CORE_NAMESPACE}}}record"):
        c_type = record.get(f"{{{C_NAMESPACE}}}type")
        if c_type not in boxed_types:
            continue

        symbol_prefix = boxed_types.pop(c_type)
        record.set("copy-function", f"{symbol_prefix}_ref")
        record.set("free-function", f"{symbol_prefix}_unref")
        record.set(f"{{{GLIB_NAMESPACE}}}type-name", c_type)
        record.set(f"{{{GLIB_NAMESPACE}}}get-type", f"{symbol_prefix}_get_type")

    if boxed_types:
        missing = ", ".join(sorted(boxed_types))
        raise ValueError(f"boxed types missing from GIR: {missing}")

    tree.write(output_path, encoding="unicode", xml_declaration=True)


if __name__ == "__main__":
    main()
