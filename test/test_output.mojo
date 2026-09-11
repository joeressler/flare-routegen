"""Output safety, formatting, and stale-check tests."""

from std.os import makedirs
from std.pathlib import Path
from std.tempfile import TemporaryDirectory
from std.testing import assert_equal, assert_false, assert_true, TestSuite

from flare_routegen.diagnostics import (
    Diagnostic,
    FRG012,
    FRG013,
    FRG014,
    FRG018,
)
from flare_routegen.discover import package_root_path
from flare_routegen.format import format_file
from flare_routegen.output import (
    build_source_snapshot,
    check_routes,
    generate_routes,
    has_generated_marker,
    sibling_temp_path,
    snapshot_unchanged,
    validate_overwrite_allowed,
)
from flare_routegen.render_comptime import (
    GENERATED_MARKER_1,
    GENERATED_MARKER_2,
)


comptime APP_SOURCE = "test/fixtures/app_basic/src"
comptime APP_PACKAGE = "my_app"


def diagnostics_contain_code(
    diagnostics: List[Diagnostic], code: String
) -> Bool:
    for diagnostic in diagnostics:
        if diagnostic.code == code:
            return True
    return False


def test_has_generated_marker_requires_both_lines() raises:
    assert_true(
        has_generated_marker(GENERATED_MARKER_1 + "\n" + GENERATED_MARKER_2)
    )
    assert_false(has_generated_marker(GENERATED_MARKER_1))
    assert_false(has_generated_marker("def user_code() -> None:\n    pass\n"))


def test_validate_overwrite_rejects_unmarked_file() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        Path(output).write_text(
            "def user_code(req: String) -> String:\n    return req\n"
        )
        var diagnostics = validate_overwrite_allowed(Path(output))
        assert_equal(len(diagnostics), 1)
        assert_equal(diagnostics[0].code, FRG012)


def test_format_file_reports_frg014_for_failing_formatter() raises:
    with TemporaryDirectory() as tmpdir:
        var path = tmpdir + "/broken.mojo"
        Path(path).write_text("def x() -> None:\n    pass\n")
        var diagnostics = format_file(path, "false")
        assert_equal(len(diagnostics), 1)
        assert_equal(diagnostics[0].code, FRG014)


def test_generate_writes_formatted_output_without_temp_file() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/_generated_routes.mojo"
        var diagnostics = generate_routes(
            APP_SOURCE,
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(diagnostics), 0)
        assert_true(Path(output).exists())
        assert_false(Path(sibling_temp_path(output)).exists())
        var content = Path(output).read_text()
        assert_true(has_generated_marker(content))
        assert_true(content.find("comptime ROUTES") >= 0)


def test_generate_refuses_unsafe_overwrite() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        Path(output).write_text(
            "def user_code(req: String) -> String:\n    return req\n"
        )
        var diagnostics = generate_routes(
            APP_SOURCE,
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(diagnostics), 1)
        assert_equal(diagnostics[0].code, FRG012)
        assert_equal(
            Path(output).read_text(),
            "def user_code(req: String) -> String:\n    return req\n",
        )


def test_check_missing_output_reports_frg013() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/missing.mojo"
        var diagnostics = check_routes(
            APP_SOURCE,
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(diagnostics), 1)
        assert_equal(diagnostics[0].code, FRG013)


def test_check_stale_output_reports_frg013_without_rewrite() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/stale.mojo"
        Path(output).write_text(
            GENERATED_MARKER_1 + "\n" + GENERATED_MARKER_2 + "\nstale\n"
        )
        var diagnostics = check_routes(
            APP_SOURCE,
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(diagnostics), 1)
        assert_equal(diagnostics[0].code, FRG013)
        assert_true(Path(output).read_text().find("stale") >= 0)


def test_check_passes_after_generate() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        var generate_errors = generate_routes(
            APP_SOURCE,
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(generate_errors), 0)
        var check_errors = check_routes(
            APP_SOURCE,
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(check_errors), 0)


def test_snapshot_unchanged_detects_mutation() raises:
    var root = Path(package_root_path(APP_SOURCE, APP_PACKAGE))
    var snapshot = build_source_snapshot(root, List[String](), "")
    assert_true(snapshot_unchanged(root, snapshot))
    var home = Path(APP_SOURCE) / "my_app" / "views" / "home.mojo"
    var original = home.read_text()
    home.write_text(original + "\n")
    assert_false(snapshot_unchanged(root, snapshot))
    home.write_text(original)


def test_in_tree_user_module_output_reports_frg018() raises:
    with TemporaryDirectory() as tmpdir:
        var root = Path(tmpdir) / "src" / "my_app"
        makedirs(String(root), exist_ok=True)
        makedirs(String(root / "views"), exist_ok=True)
        (root / "views" / "home.mojo").write_text(
            "# @flare.route GET /\n\ndef home(req: String) -> String:\n   "
            " return req\n"
        )
        var output = String(root / "views" / "home.mojo")
        var diagnostics = generate_routes(
            String(Path(tmpdir) / "src"),
            APP_PACKAGE,
            output,
            List[String](),
        )
        assert_equal(len(diagnostics), 1)
        assert_equal(diagnostics[0].code, FRG018)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
