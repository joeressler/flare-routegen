"""Module-path mapping and handler alias generation."""

from flare_routegen.diagnostics import (
    Diagnostic,
    FRG009,
    FRG010,
    FRG011,
    make_diagnostic,
)
from flare_routegen.models import (
    DiscoveredRoute,
    HANDLER_KIND_STRUCT,
)
from flare_routegen.text_util import remove_extension, text_len, text_slice


@fieldwise_init
struct MappedSourceFile(Copyable, Movable):
    """A scanned source file and its derived module path."""

    var relative_path: String
    var module_path: String


def is_valid_module_segment(segment: String) -> Bool:
    if segment == "":
        return False
    var first = text_slice(segment, 0, 1)
    if not (
        (first >= "A" and first <= "Z")
        or (first >= "a" and first <= "z")
        or first == "_"
    ):
        return False
    for i in range(1, text_len(segment)):
        var ch = text_slice(segment, i, i + 1)
        if (
            (ch >= "A" and ch <= "Z")
            or (ch >= "a" and ch <= "z")
            or (ch >= "0" and ch <= "9")
            or ch == "_"
        ):
            continue
        return False
    return True


def module_suffix_from_relative(relative_path: String) -> String:
    var without_ext = remove_extension(relative_path)
    if without_ext == "":
        return ""
    var raw_segments = without_ext.split("/")
    var segments = List[String]()
    for segment in raw_segments:
        segments.append(String(segment))
    if len(segments) > 0 and segments[len(segments) - 1] == "__init__":
        _ = segments.pop()
    if len(segments) == 0:
        return ""
    var result = segments[0]
    for i in range(1, len(segments)):
        result += "." + segments[i]
    return result


def module_path_for_file(package_name: String, relative_path: String) -> String:
    var module_suffix = module_suffix_from_relative(relative_path)
    if module_suffix == "":
        return package_name
    if package_name == "":
        return module_suffix
    return package_name + "." + module_suffix


def module_path_underscored(module_path: String) -> String:
    return module_path.replace(".", "_")


def handler_import_alias(module_path: String, handler_symbol: String) -> String:
    return "_frg_" + module_path_underscored(module_path) + "_" + handler_symbol


def handler_wrapper_name(module_path: String, handler_symbol: String) -> String:
    return (
        "_frg_wrap_"
        + module_path_underscored(module_path)
        + "_"
        + handler_symbol
    )


def validate_module_path_segments(
    module_path: String, relative_path: String
) -> Optional[Diagnostic]:
    if module_path == "":
        return Optional[Diagnostic](
            make_diagnostic(
                FRG010,
                relative_path,
                1,
                1,
                "invalid module path segment in `" + module_path + "`",
                (
                    "use valid Mojo identifier segments in file and directory"
                    " names"
                ),
            )
        )
    var segments = module_path.split(".")
    for segment in segments:
        if not is_valid_module_segment(String(segment)):
            return Optional[Diagnostic](
                make_diagnostic(
                    FRG010,
                    relative_path,
                    1,
                    1,
                    "invalid module path segment `" + String(segment) + "`",
                    (
                        "use valid Mojo identifier segments in file and"
                        " directory names"
                    ),
                )
            )
    return Optional[Diagnostic]()


def append_frg009_for_module(
    module_path: String,
    paths: List[String],
    mut diagnostics: List[Diagnostic],
) -> None:
    if len(paths) <= 1:
        return
    for path in paths:
        var others = List[String]()
        for other in paths:
            if other != path:
                others.append(other)
        var correction = "rename one of the colliding source files"
        if len(others) > 0:
            correction = (
                "rename one of `" + paths[0] + "` or `" + paths[1] + "`"
            )
        diagnostics.append(
            make_diagnostic(
                FRG009,
                path,
                1,
                1,
                "ambiguous module mapping for `" + module_path + "`",
                correction,
            )
        )


def validate_mapped_files(
    mapped_files: List[MappedSourceFile],
) raises -> List[Diagnostic]:
    var diagnostics = List[Diagnostic]()
    var paths_by_module = Dict[String, List[String]]()

    for mapped in mapped_files:
        var segment_error = validate_module_path_segments(
            mapped.module_path, mapped.relative_path
        )
        if segment_error:
            diagnostics.append(segment_error.value().copy())

        if mapped.module_path not in paths_by_module:
            paths_by_module[mapped.module_path] = List[String]()
        paths_by_module[mapped.module_path].append(mapped.relative_path)

    for module_path in paths_by_module:
        append_frg009_for_module(
            module_path, paths_by_module[module_path], diagnostics
        )

    return diagnostics^


def validate_handler_aliases(
    routes: List[DiscoveredRoute],
) raises -> List[Diagnostic]:
    var diagnostics = List[Diagnostic]()
    var keys_by_alias = Dict[String, List[String]]()

    for route in routes:
        var import_alias = handler_import_alias(
            route.module_path, route.handler_symbol
        )
        var key = route.module_path + "\t" + route.handler_symbol
        if import_alias not in keys_by_alias:
            keys_by_alias[import_alias] = List[String]()
        var found = False
        for existing in keys_by_alias[import_alias]:
            if existing == key:
                found = True
                break
        if not found:
            keys_by_alias[import_alias].append(key)

    for route in routes:
        var import_alias = handler_import_alias(
            route.module_path, route.handler_symbol
        )
        if len(keys_by_alias[import_alias]) > 1:
            diagnostics.append(
                make_diagnostic(
                    FRG011,
                    route.source_path,
                    route.directive_line,
                    route.directive_column,
                    "ambiguous generated handler import alias `"
                    + import_alias
                    + "`",
                    "rename one of the colliding handlers",
                )
            )

    return diagnostics^


def unique_handlers_sorted(
    routes: List[DiscoveredRoute],
) raises -> List[Tuple[String, String, String]]:
    var handlers = List[Tuple[String, String, String]]()
    var seen = Dict[String, Bool]()
    for route in routes:
        var key = route.module_path + "\t" + route.handler_symbol
        if key in seen:
            continue
        seen[key] = True
        handlers.append(
            (route.module_path, route.handler_symbol, route.handler_kind)
        )

    var count = len(handlers)
    for i in range(count):
        for j in range(i + 1, count):
            var left = handlers[i]
            var right = handlers[j]
            if (right[0], right[1]) < (left[0], left[1]):
                var tmp = handlers[i]
                handlers[i] = handlers[j]
                handlers[j] = tmp
    return handlers^


def is_struct_handler(handler_kind: String) -> Bool:
    return handler_kind == HANDLER_KIND_STRUCT


def any_struct_handler(routes: List[DiscoveredRoute]) -> Bool:
    for route in routes:
        if is_struct_handler(route.handler_kind):
            return True
    return False


def wrapper_call_line(import_alias: String, handler_kind: String) -> String:
    """Emit the wrapper body call for a function or Extracted struct handler."""
    if is_struct_handler(handler_kind):
        return "    return Extracted[" + import_alias + "]().serve(req)"
    return "    return " + import_alias + "(req)"
