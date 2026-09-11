"""Formatter integration for generated route output."""

from std.subprocess import run

from flare_routegen.diagnostics import Diagnostic, FRG014, make_diagnostic
from flare_routegen.text_util import text_len, text_slice

comptime EXIT_TRAILER_PREFIX = "__FRG_EXIT__:"
comptime DEFAULT_FORMAT_BIN = "mojo format --quiet"


def shell_quote(text: String) -> String:
    return "'" + text.replace("'", "'\"'\"'") + "'"


def build_format_shell(
    path: String, formatter: String = DEFAULT_FORMAT_BIN
) -> String:
    return "sh -c " + shell_quote(
        formatter
        + " "
        + shell_quote(path)
        + "; printf '"
        + EXIT_TRAILER_PREFIX
        + '%s\' "$?"'
    )


def parse_command_exit(output: String) -> Int:
    var index = output.rfind(EXIT_TRAILER_PREFIX)
    if index < 0:
        return -1
    var start = index + text_len(EXIT_TRAILER_PREFIX)
    var trailer = text_slice(output, start, text_len(output))
    try:
        return Int(trailer)
    except e:
        return -1


def format_file(
    path: String,
    formatter: String = DEFAULT_FORMAT_BIN,
) raises -> List[Diagnostic]:
    var command = build_format_shell(path, formatter)
    var output = run(command)
    var exit_code = parse_command_exit(output)
    if exit_code != 0:
        var diagnostics = List[Diagnostic]()
        diagnostics.append(
            make_diagnostic(
                FRG014,
                path,
                1,
                1,
                "failed to format generated output",
                (
                    "ensure `mojo format` is available and the output is valid"
                    " Mojo"
                ),
            )
        )
        return diagnostics^
    return List[Diagnostic]()
