"""Package-root discovery for flare-routegen."""

from std.os import path as os_path
from std.pathlib import Path

from flare_routegen.diagnostics import (
    Diagnostic,
    FRG008,
    FRG017,
    make_diagnostic,
    sort_key,
)
from flare_routegen.models import DiscoveredRoute, DiscoverResult
from flare_routegen.module_map import (
    MappedSourceFile,
    module_path_for_file,
    validate_mapped_files,
)
from flare_routegen.scan import scan_file_content
from flare_routegen.text_util import text_drop_prefix, text_len, text_slice


def package_root_path(source: String, package_name: String) -> String:
    var root = Path(source)
    if package_name != "":
        var segments = package_name.split(".")
        for segment in segments:
            root = root / segment
    return String(root)


def is_ignored_dir(name: String) -> Bool:
    return (
        name == ".git"
        or name == ".pixi"
        or name == "build"
        or name == "dist"
        or name == "target"
        or name == "output"
        or name == "__mojocache__"
        or name == "__pycache__"
    )


def has_supported_extension(file_path: String) -> Bool:
    return file_path.endswith(".mojo") or file_path.endswith(".🔥")


def glob_match(pattern: String, value: String) -> Bool:
    if pattern == "*":
        return True
    if pattern.find("*") < 0:
        return pattern == value
    if pattern.startswith("*") and pattern.endswith("*"):
        var middle = text_slice(pattern, 1, text_len(pattern) - 1)
        return value.find(middle) >= 0
    if pattern.startswith("*"):
        var suffix = text_drop_prefix(pattern, 1)
        return value.endswith(suffix)
    if pattern.endswith("*"):
        var prefix = text_slice(pattern, 0, text_len(pattern) - 1)
        return value.startswith(prefix)
    return False


def is_excluded(relative_path: String, excludes: List[String]) -> Bool:
    for pattern in excludes:
        if glob_match(pattern, relative_path):
            return True
    return False


def relative_path_string(root: Path, file_path: Path) -> String:
    var root_text = String(root)
    var file_text = String(file_path)
    var prefix = root_text + "/"
    if file_text.startswith(prefix):
        return String(file_text[byte = text_len(prefix) :])
    return file_text


def route_index_before(
    routes: List[DiscoveredRoute], left_index: Int, right_index: Int
) -> Bool:
    var left_key = (
        routes[left_index].module_path,
        routes[left_index].source_path,
        routes[left_index].directive_line,
        routes[left_index].method,
        routes[left_index].normalized_path,
        routes[left_index].handler_symbol,
    )
    var right_key = (
        routes[right_index].module_path,
        routes[right_index].source_path,
        routes[right_index].directive_line,
        routes[right_index].method,
        routes[right_index].normalized_path,
        routes[right_index].handler_symbol,
    )
    return left_key < right_key


def sort_routes(mut routes: List[DiscoveredRoute]) -> None:
    var count = len(routes)
    for i in range(count):
        for j in range(i + 1, count):
            if route_index_before(routes, j, i):
                var tmp = routes[i].copy()
                routes[i] = routes[j].copy()
                routes[j] = tmp.copy()


def diagnostic_index_before(
    diagnostics: List[Diagnostic], left_index: Int, right_index: Int
) -> Bool:
    var left_key = (
        diagnostics[left_index].source_path,
        diagnostics[left_index].line,
        diagnostics[left_index].column,
        diagnostics[left_index].code,
    )
    var right_key = (
        diagnostics[right_index].source_path,
        diagnostics[right_index].line,
        diagnostics[right_index].column,
        diagnostics[right_index].code,
    )
    return left_key < right_key


def sort_diagnostics(mut diagnostics: List[Diagnostic]) -> None:
    var count = len(diagnostics)
    for i in range(count):
        for j in range(i + 1, count):
            if diagnostic_index_before(diagnostics, j, i):
                var tmp = diagnostics[i].copy()
                diagnostics[i] = diagnostics[j].copy()
                diagnostics[j] = tmp.copy()


def sort_paths(mut entries: List[Path]) -> None:
    var count = len(entries)
    for i in range(count):
        for j in range(i + 1, count):
            if entries[j].name() < entries[i].name():
                var tmp = entries[i]
                entries[i] = entries[j]
                entries[j] = tmp


def collect_files(
    root: Path,
    current: Path,
    excludes: List[String],
    mut files: List[Path],
) raises -> None:
    if os_path.islink(String(current)):
        return

    var entries = current.listdir()
    sort_paths(entries)

    for entry in entries:
        var child = current / entry.name()
        var entry_path = String(child)
        var relative = relative_path_string(root, child)

        if os_path.islink(entry_path):
            continue

        if child.is_dir():
            if is_ignored_dir(String(entry.name())):
                continue
            collect_files(root, child, excludes, files)
            continue

        if not has_supported_extension(String(entry.name())):
            continue

        if is_excluded(relative, excludes):
            continue

        files.append(child)


def check_duplicate_routes(
    routes: List[DiscoveredRoute],
    mut diagnostics: List[Diagnostic],
) raises -> None:
    var seen = Dict[String, Int]()
    for i in range(len(routes)):
        var key = routes[i].method + "\t" + routes[i].normalized_path
        if key in seen:
            var first_index = seen[key]
            diagnostics.append(
                make_diagnostic(
                    FRG008,
                    routes[i].source_path,
                    routes[i].directive_line,
                    routes[i].directive_column,
                    "duplicate route registration for "
                    + routes[i].method
                    + " "
                    + routes[i].normalized_path,
                    "remove one of the duplicate directives",
                )
            )
            diagnostics.append(
                make_diagnostic(
                    FRG008,
                    routes[first_index].source_path,
                    routes[first_index].directive_line,
                    routes[first_index].directive_column,
                    "duplicate route registration for "
                    + routes[first_index].method
                    + " "
                    + routes[first_index].normalized_path,
                    "remove one of the duplicate directives",
                )
            )
            continue
        seen[key] = i


def discover_routes(
    source: String,
    package_name: String,
    excludes: List[String],
) raises -> DiscoverResult:
    var root_text = package_root_path(source, package_name)
    var root = Path(root_text)
    if not root.exists() or not root.is_dir():
        raise Error("package root does not exist: " + root_text)

    var files = List[Path]()
    collect_files(root, root, excludes, files)

    var mapped_files = List[MappedSourceFile]()
    for file_path in files:
        var relative = relative_path_string(root, file_path)
        mapped_files.append(
            MappedSourceFile(
                relative,
                module_path_for_file(package_name, relative),
            )
        )

    var diagnostics = validate_mapped_files(mapped_files)
    if len(diagnostics) > 0:
        sort_diagnostics(diagnostics)
        return DiscoverResult(List[DiscoveredRoute](), diagnostics^)

    var routes = List[DiscoveredRoute]()

    for mapped in mapped_files:
        var relative = mapped.relative_path
        var module_path = mapped.module_path
        var file_path = root
        for segment in relative.split("/"):
            file_path = file_path / String(segment)
        var content: String
        try:
            content = file_path.read_text()
        except e:
            diagnostics.append(
                make_diagnostic(
                    FRG017,
                    relative,
                    1,
                    1,
                    "unable to read source file",
                    "ensure the file is valid UTF-8 text",
                )
            )
            continue

        var scanned = scan_file_content(content, relative, module_path)
        for route in scanned.routes:
            routes.append(route.copy())
        for diagnostic in scanned.diagnostics:
            diagnostics.append(diagnostic.copy())

    sort_routes(routes)
    check_duplicate_routes(routes, diagnostics)
    sort_diagnostics(diagnostics)

    if diagnostics:
        return DiscoverResult(List[DiscoveredRoute](), diagnostics^)

    return DiscoverResult(routes^, diagnostics^)


def join_lines(lines: List[String]) -> String:
    if len(lines) == 0:
        return ""
    var result = lines[0]
    for i in range(1, len(lines)):
        result += "\n" + lines[i]
    return result


def format_list_output(result: DiscoverResult) -> String:
    var lines = List[String]()
    for route in result.routes:
        lines.append(route.format_list_row())
    if len(lines) == 0:
        return ""
    return join_lines(lines) + "\n"


def format_diagnostics_output(diagnostics: List[Diagnostic]) -> String:
    var lines = List[String]()
    for diagnostic in diagnostics:
        lines.append(diagnostic.format())
    if len(lines) == 0:
        return ""
    return join_lines(lines) + "\n"
