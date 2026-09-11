"""Atomic output generation and stale checking."""

from std.ffi import c_char, external_call
from std.os import makedirs, remove
from std.pathlib import Path

from flare_routegen.diagnostics import (
    Diagnostic,
    FRG012,
    FRG013,
    FRG015,
    FRG018,
    make_diagnostic,
)
from flare_routegen.discover import (
    collect_files,
    discover_routes,
    package_root_path,
    relative_path_string,
)
from flare_routegen.format import format_file
from flare_routegen.render_comptime import (
    GENERATED_MARKER_1,
    GENERATED_MARKER_2,
    render_comptime,
)
from flare_routegen.text_util import text_len

comptime TEMP_SUFFIX = ".frg.tmp.mojo"


def has_generated_marker(content: String) -> Bool:
    return (
        content.find(GENERATED_MARKER_1) >= 0
        and content.find(GENERATED_MARKER_2) >= 0
    )


def parent_directory(path: String) -> Optional[String]:
    var slash = path.rfind("/")
    if slash < 0:
        return Optional[String]()
    return Optional[String](String(path[byte=0:slash]))


def ensure_parent_directory(path: String) raises -> None:
    var parent = parent_directory(path)
    if parent:
        makedirs(parent.value(), exist_ok=True)


def relative_path_under_root(root: Path, file_path: Path) -> Optional[String]:
    var root_text = String(root)
    var file_text = String(file_path)
    var prefix = root_text + "/"
    if file_text.startswith(prefix):
        return Optional[String](String(file_text[byte = text_len(prefix) :]))
    if file_text == root_text:
        return Optional[String]("")
    return Optional[String]()


def exclude_contains(excludes: List[String], relative: String) -> Bool:
    for pattern in excludes:
        if pattern == relative:
            return True
    return False


def append_exclude_if_missing(
    mut excludes: List[String], relative: String
) -> None:
    if relative == "":
        return
    if exclude_contains(excludes, relative):
        return
    excludes.append(relative)


def posix_rename(old_path: String, new_path: String) raises -> None:
    var old_mut = old_path
    var new_mut = new_path
    var result = external_call["rename", Int](
        old_mut.as_c_string_slice().unsafe_ptr(),
        new_mut.as_c_string_slice().unsafe_ptr(),
    )
    if result != 0:
        raise Error(
            "failed to replace output file `"
            + new_path
            + "` from temporary file"
        )


def sibling_temp_path(output_path: String) -> String:
    if output_path.endswith(".mojo"):
        return output_path[byte = 0 : text_len(output_path) - 5] + TEMP_SUFFIX
    return output_path + TEMP_SUFFIX


def copy_diagnostics(diagnostics: List[Diagnostic]) -> List[Diagnostic]:
    var copied = List[Diagnostic]()
    for diagnostic in diagnostics:
        copied.append(diagnostic.copy())
    return copied^


def build_source_snapshot(
    root: Path,
    excludes: List[String],
    skip_relative: String,
) raises -> Dict[String, String]:
    var files = List[Path]()
    collect_files(root, root, excludes, files)
    var snapshot = Dict[String, String]()
    for file_path in files:
        var relative = relative_path_string(root, file_path)
        if skip_relative != "" and relative == skip_relative:
            continue
        snapshot[relative] = file_path.read_text()
    return snapshot^


def snapshot_unchanged(
    root: Path, snapshot: Dict[String, String]
) raises -> Bool:
    for relative in snapshot:
        var file_path = root
        for segment in relative.split("/"):
            file_path = file_path / String(segment)
        if file_path.read_text() != snapshot[relative]:
            return False
    return True


def output_diagnostic(
    code: String, output_path: String, message: String, correction: String
) -> Diagnostic:
    return make_diagnostic(code, output_path, 1, 1, message, correction)


def validate_in_tree_output(
    root: Path,
    output_path: Path,
    excludes: List[String],
) raises -> List[Diagnostic]:
    var diagnostics = List[Diagnostic]()
    var relative = relative_path_under_root(root, output_path)
    if not relative:
        return diagnostics^

    if not output_path.exists():
        return diagnostics^

    var files = List[Path]()
    collect_files(root, root, excludes, files)
    for file_path in files:
        if relative_path_string(root, file_path) != relative.value():
            continue
        var content = file_path.read_text()
        if not has_generated_marker(content):
            diagnostics.append(
                output_diagnostic(
                    FRG018,
                    String(output_path),
                    "output path falls inside scanned package sources",
                    "choose a dedicated generated output file or add --exclude",
                )
            )
        break
    return diagnostics^


def validate_overwrite_allowed(output_path: Path) raises -> List[Diagnostic]:
    var diagnostics = List[Diagnostic]()
    if not output_path.exists():
        return diagnostics^
    var content = output_path.read_text()
    if has_generated_marker(content):
        return diagnostics^
    diagnostics.append(
        output_diagnostic(
            FRG012,
            String(output_path),
            "refusing to overwrite file without generated marker",
            "remove the file or write to a dedicated generated output path",
        )
    )
    return diagnostics^


def append_effective_excludes(
    root: Path,
    output_path: Path,
    excludes: List[String],
    mut effective: List[String],
) -> String:
    for pattern in excludes:
        effective.append(pattern)
    var skip_relative = ""
    var relative = relative_path_under_root(root, output_path)
    if relative:
        skip_relative = relative.value()
        append_exclude_if_missing(effective, skip_relative)
    return skip_relative


def format_rendered_bytes(
    output_path: String,
    rendered: String,
    formatter: String = "",
) raises -> Tuple[Optional[String], List[Diagnostic]]:
    var temp_path = sibling_temp_path(output_path)
    ensure_parent_directory(temp_path)
    var temp = Path(temp_path)
    temp.write_text(rendered)
    var format_errors: List[Diagnostic]
    if formatter == "":
        format_errors = format_file(temp_path)
    else:
        format_errors = format_file(temp_path, formatter)
    if len(format_errors) > 0:
        _ = remove(temp_path)
        return (Optional[String](), format_errors^)
    var formatted = temp.read_text()
    _ = remove(temp_path)
    return (Optional[String](formatted), List[Diagnostic]())


def prepare_pipeline(
    source: String,
    package_name: String,
    output_path: String,
    excludes: List[String],
    formatter: String = "",
) raises -> Tuple[Optional[String], List[Diagnostic], Dict[String, String]]:
    var root = Path(package_root_path(source, package_name))
    var output = Path(output_path)
    var effective_excludes = List[String]()
    var skip_relative = append_effective_excludes(
        root, output, excludes, effective_excludes
    )

    var in_tree_errors = validate_in_tree_output(root, output, excludes)
    if len(in_tree_errors) > 0:
        return (Optional[String](), in_tree_errors^, Dict[String, String]())

    var discovered = discover_routes(source, package_name, effective_excludes)
    if len(discovered.diagnostics) > 0:
        return (
            Optional[String](),
            copy_diagnostics(discovered.diagnostics),
            Dict[String, String](),
        )

    var rendered = render_comptime(discovered.routes)
    if len(rendered[1]) > 0:
        return (
            Optional[String](),
            copy_diagnostics(rendered[1]),
            Dict[String, String](),
        )

    var snapshot = build_source_snapshot(
        root, effective_excludes, skip_relative
    )
    var formatted_result = format_rendered_bytes(
        output_path, rendered[0], formatter
    )
    if len(formatted_result[1]) > 0:
        return (
            Optional[String](),
            copy_diagnostics(formatted_result[1]),
            Dict[String, String](),
        )
    return (formatted_result[0], List[Diagnostic](), snapshot^)


def generate_routes(
    source: String,
    package_name: String,
    output_path: String,
    excludes: List[String],
    formatter: String = "",
) raises -> List[Diagnostic]:
    var output = Path(output_path)
    var overwrite_errors = validate_overwrite_allowed(output)
    if len(overwrite_errors) > 0:
        return overwrite_errors^

    var prepared = prepare_pipeline(
        source, package_name, output_path, excludes, formatter
    )
    if len(prepared[1]) > 0:
        return copy_diagnostics(prepared[1])
    if not prepared[0]:
        return List[Diagnostic]()

    var formatted = prepared[0].value()
    var root = Path(package_root_path(source, package_name))

    if not snapshot_unchanged(root, prepared[2]):
        var diagnostics = List[Diagnostic]()
        diagnostics.append(
            output_diagnostic(
                FRG015,
                output_path,
                "source inputs changed during generation",
                "retry generate after source files stabilize",
            )
        )
        return diagnostics^

    var temp_path = sibling_temp_path(output_path)
    ensure_parent_directory(temp_path)
    ensure_parent_directory(output_path)
    Path(temp_path).write_text(formatted)
    posix_rename(temp_path, output_path)
    return List[Diagnostic]()


def check_routes(
    source: String,
    package_name: String,
    output_path: String,
    excludes: List[String],
    formatter: String = "",
) raises -> List[Diagnostic]:
    var output = Path(output_path)
    if not output.exists():
        var missing = List[Diagnostic]()
        missing.append(
            output_diagnostic(
                FRG013,
                output_path,
                "generated output file is missing",
                "run `flare-routegen generate` to create it",
            )
        )
        return missing^

    var prepared = prepare_pipeline(
        source, package_name, output_path, excludes, formatter
    )
    if len(prepared[1]) > 0:
        return copy_diagnostics(prepared[1])
    if not prepared[0]:
        return List[Diagnostic]()

    var formatted = prepared[0].value()
    var existing = output.read_text()
    if existing != formatted:
        var stale = List[Diagnostic]()
        stale.append(
            output_diagnostic(
                FRG013,
                output_path,
                "generated output is stale",
                "run `flare-routegen generate` to refresh it",
            )
        )
        return stale^
    return List[Diagnostic]()
