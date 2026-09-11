"""Directive grammar parsing for flare-routegen."""

from flare_routegen.diagnostics import (
    Diagnostic,
    FRG001,
    FRG002,
    FRG003,
    FRG004,
    make_diagnostic,
)
from flare_routegen.text_util import (
    text_char_at,
    text_drop_prefix,
    text_len,
    text_slice,
)


comptime DIRECTIVE_MARKER = "@flare.route"


@fieldwise_init
struct ParsedDirective(Copyable, Movable):
    """A successfully parsed route directive."""

    var method: String
    var path: String
    var normalized_path: String


def is_space_or_tab(ch: String) -> Bool:
    return ch == " " or ch == "\t"


def skip_spaces_tabs(text: String, start: Int) -> Int:
    var index = start
    while index < text_len(text):
        var ch = text_char_at(text, index)
        if is_space_or_tab(ch):
            index += 1
            continue
        break
    return index


def normalize_path(path: String) -> String:
    if path == "/":
        return "/"
    var trimmed = String(path.rstrip("/"))
    if trimmed == "":
        return "/"
    return trimmed


def is_supported_method(method: String) -> Bool:
    return (
        method == "GET"
        or method == "POST"
        or method == "PUT"
        or method == "PATCH"
        or method == "DELETE"
        or method == "HEAD"
        or method == "OPTIONS"
    )


def looks_like_directive_comment(body: String) -> Bool:
    var index = skip_spaces_tabs(body, 0)
    return text_drop_prefix(body, index).startswith(DIRECTIVE_MARKER)


def looks_like_directive_line(line: String) -> Bool:
    if text_len(line) == 0 or text_char_at(line, 0) != "#":
        return False
    return looks_like_directive_comment(text_drop_prefix(line, 1))


def next_token(text: String, start: Int) -> Tuple[String, Int]:
    var index = skip_spaces_tabs(text, start)
    if index >= text_len(text):
        return ("", index)
    var end = index
    while end < text_len(text):
        if is_space_or_tab(text_char_at(text, end)):
            break
        end += 1
    return (text_slice(text, index, end), end)


def parse_directive_line(
    line: String,
    source_path: String,
    line_no: Int,
    column: Int,
) -> Tuple[Optional[ParsedDirective], Optional[Diagnostic]]:
    if not looks_like_directive_line(line):
        return (Optional[ParsedDirective](), Optional[Diagnostic]())

    var body = text_drop_prefix(line, 1)
    var index = skip_spaces_tabs(body, 0)
    if not text_drop_prefix(body, index).startswith(DIRECTIVE_MARKER):
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG001,
                    source_path,
                    line_no,
                    column,
                    "malformed route directive",
                    "use `# @flare.route <METHOD> <PATH>`",
                )
            ),
        )

    index += text_len(DIRECTIVE_MARKER)
    if index >= text_len(body) or not is_space_or_tab(
        text_char_at(body, index)
    ):
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG001,
                    source_path,
                    line_no,
                    column,
                    "malformed route directive",
                    "use `# @flare.route <METHOD> <PATH>`",
                )
            ),
        )

    var method_token = next_token(body, index)
    var method = method_token[0]
    index = method_token[1]
    if method == "":
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG001,
                    source_path,
                    line_no,
                    column,
                    "malformed route directive",
                    "use `# @flare.route <METHOD> <PATH>`",
                )
            ),
        )

    if not is_supported_method(method):
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG002,
                    source_path,
                    line_no,
                    column,
                    "unsupported HTTP method `" + method + "`",
                    "use GET, POST, PUT, PATCH, DELETE, HEAD, or OPTIONS",
                )
            ),
        )

    index = skip_spaces_tabs(body, index)
    var path_start = index
    var path_end = index
    while path_end < text_len(body):
        var ch = text_char_at(body, path_end)
        if is_space_or_tab(ch) or ch == "#":
            break
        path_end += 1

    var path = text_slice(body, path_start, path_end)
    index = path_end

    if path == "":
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG003,
                    source_path,
                    line_no,
                    column,
                    "missing or invalid route path",
                    "path must begin with `/`",
                )
            ),
        )

    if path.startswith('"') or path.startswith("'"):
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG003,
                    source_path,
                    line_no,
                    column,
                    "quoted route paths are not supported",
                    "use an unquoted path such as `/users/:id`",
                )
            ),
        )

    if text_char_at(path, 0) != "/":
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG003,
                    source_path,
                    line_no,
                    column,
                    "missing or invalid route path",
                    "path must begin with `/`",
                )
            ),
        )

    index = skip_spaces_tabs(body, index)
    if index < text_len(body) and text_char_at(body, index) != "#":
        return (
            Optional[ParsedDirective](),
            Optional[Diagnostic](
                make_diagnostic(
                    FRG004,
                    source_path,
                    line_no,
                    column,
                    "unknown token after route path",
                    "use only `# @flare.route <METHOD> <PATH>`",
                )
            ),
        )

    return (
        Optional[ParsedDirective](
            ParsedDirective(method, path, normalize_path(path))
        ),
        Optional[Diagnostic](),
    )
