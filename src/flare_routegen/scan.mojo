"""Per-file route directive scanner."""

from flare_routegen.diagnostics import (
    Diagnostic,
    FRG005,
    FRG006,
    FRG007,
    make_diagnostic,
)
from flare_routegen.grammar import (
    looks_like_directive_line,
    parse_directive_line,
)
from flare_routegen.models import (
    DiscoveredRoute,
    PendingDirective,
    ScanFileResult,
)
from flare_routegen.text_util import (
    text_char_at,
    text_drop_prefix,
    text_len,
    text_slice,
)


def leading_indent(line: String) -> Int:
    var count = 0
    while count < text_len(line):
        var ch = text_char_at(line, count)
        if ch == " " or ch == "\t":
            count += 1
            continue
        break
    return count


def is_blank_line(line: String) -> Bool:
    return leading_indent(line) == text_len(line)


def is_decorator_line(line: String) -> Bool:
    return line.lstrip(" \t").startswith("@")


def is_comment_line(line: String) -> Bool:
    return line.lstrip(" \t").startswith("#")


def extract_def_name(line: String) -> Optional[String]:
    var stripped = String(line.lstrip(" \t"))
    if not stripped.startswith("def "):
        return Optional[String]()
    var rest = text_drop_prefix(stripped, 4)
    var end = 0
    while end < text_len(rest):
        var ch = text_char_at(rest, end)
        if ch == "(" or ch == " " or ch == "\t":
            break
        end += 1
    if end == 0:
        return Optional[String]()
    return Optional[String](text_slice(rest, 0, end))


def count_delimiter(line: String, delimiter: String) -> Int:
    var count = 0
    var start = 0
    while True:
        var index = line.find(delimiter, start)
        if index < 0:
            break
        count += 1
        start = index + text_len(delimiter)
    return count


def update_triple_quote_state(line: String, in_triple_quote: Bool) -> Bool:
    var triple_double = count_delimiter(line, '"""')
    var triple_single = count_delimiter(line, "'''")
    var toggles = triple_double + triple_single
    if toggles % 2 == 1:
        return not in_triple_quote
    return in_triple_quote


def orphan_pending(
    mut pending: List[PendingDirective],
    source_path: String,
    mut diagnostics: List[Diagnostic],
) -> None:
    for item in pending:
        diagnostics.append(
            make_diagnostic(
                FRG006,
                source_path,
                item.directive_line,
                item.directive_column,
                "route directive is not followed by a top-level handler",
                "place the directive immediately before the handler `def`",
            )
        )
    pending.clear()


def bind_pending(
    mut pending: List[PendingDirective],
    handler_symbol: String,
    handler_line: Int,
    handler_column: Int,
    module_path: String,
    source_path: String,
    mut routes: List[DiscoveredRoute],
    mut diagnostics: List[Diagnostic],
) -> None:
    var seen_on_handler = Dict[String, Bool]()
    for item in pending:
        var key = item.method + "\t" + item.normalized_path
        if key in seen_on_handler:
            diagnostics.append(
                make_diagnostic(
                    FRG005,
                    source_path,
                    item.directive_line,
                    item.directive_column,
                    "duplicate route directive on the same handler",
                    "remove the repeated directive for "
                    + item.method
                    + " "
                    + item.normalized_path,
                )
            )
            continue
        seen_on_handler[key] = True
        routes.append(
            DiscoveredRoute(
                item.method,
                item.path,
                item.normalized_path,
                handler_symbol,
                module_path,
                source_path,
                item.directive_line,
                item.directive_column,
                handler_line,
                handler_column,
            )
        )
    pending.clear()


def scan_file_content(
    content: String,
    source_path: String,
    module_path: String,
) -> ScanFileResult:
    var routes = List[DiscoveredRoute]()
    var diagnostics = List[Diagnostic]()
    var pending = List[PendingDirective]()
    var in_triple_quote = False

    var raw_lines = content.split("\n")
    for line_no in range(len(raw_lines)):
        var line = String(raw_lines[line_no])
        var one_based_line = line_no + 1
        var indent = leading_indent(line)

        if indent == 0:
            in_triple_quote = update_triple_quote_state(line, in_triple_quote)

        if indent > 0:
            var nested = String(line.lstrip(" \t"))
            if nested.startswith("#") and looks_like_directive_line(nested):
                diagnostics.append(
                    make_diagnostic(
                        FRG007,
                        source_path,
                        one_based_line,
                        indent + 1,
                        "route directive must be at top level",
                        (
                            "move the directive to column 1 before a top-level"
                            " `def`"
                        ),
                    )
                )
            continue

        if in_triple_quote:
            continue

        if is_blank_line(line):
            continue

        if is_comment_line(line):
            var parsed = parse_directive_line(
                line, source_path, one_based_line, 1
            )
            var directive = parsed[0].copy()
            var diagnostic = parsed[1].copy()
            if diagnostic:
                diagnostics.append(diagnostic.value().copy())
                continue
            if directive:
                var value = directive.value().copy()
                pending.append(
                    PendingDirective(
                        value.method,
                        value.path,
                        value.normalized_path,
                        one_based_line,
                        1,
                    )
                )
            continue

        if is_decorator_line(line):
            continue

        var handler_name = extract_def_name(line)
        if handler_name:
            bind_pending(
                pending,
                handler_name.value(),
                one_based_line,
                indent + 1,
                module_path,
                source_path,
                routes,
                diagnostics,
            )
            continue

        orphan_pending(pending, source_path, diagnostics)

    orphan_pending(pending, source_path, diagnostics)
    return ScanFileResult(routes^, diagnostics^)
