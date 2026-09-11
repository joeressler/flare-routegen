"""CLI help/version/list/generate/check smoke tests."""

from std.pathlib import Path
from std.tempfile import TemporaryDirectory
from std.testing import assert_equal, assert_true, TestSuite

from flare_routegen.cli import dispatch, help_text, version_text
from flare_routegen.render_comptime import (
    GENERATED_MARKER_1,
    GENERATED_MARKER_2,
)
from flare_routegen.version import VERSION

comptime APP_SOURCE = "test/fixtures/app_basic/src"
comptime APP_PACKAGE = "my_app"


def args_list(*values: String) -> List[String]:
    var result = List[String]()
    for value in values:
        result.append(value)
    return result^


def test_help_text_lists_contract() raises:
    var text = help_text()
    assert_true(text.find("generate") >= 0, msg="help should mention generate")
    assert_true(text.find("check") >= 0, msg="help should mention check")
    assert_true(text.find("list") >= 0, msg="help should mention list")
    assert_true(text.find("--source") >= 0, msg="help should mention --source")
    assert_true(
        text.find("--package") >= 0, msg="help should mention --package"
    )
    assert_true(text.find("--output") >= 0, msg="help should mention --output")
    assert_true(
        text.find("METHOD<TAB>PATH") >= 0, msg="help should document list rows"
    )


def test_version_text() raises:
    assert_equal(version_text(), "flare-routegen " + VERSION + "\n")


def test_dispatch_empty_args_shows_help() raises:
    var result = dispatch(args_list())
    assert_equal(result[0], 0)
    assert_true(result[1].find("flare-routegen") >= 0)
    assert_equal(result[2], "")


def test_dispatch_help_flags() raises:
    var flags = List[String]()
    flags.append("--help")
    flags.append("-h")
    for flag in flags:
        var result = dispatch(args_list(flag))
        assert_equal(result[0], 0)
        assert_true(result[1].find("Usage:") >= 0)
        assert_equal(result[2], "")


def test_dispatch_version_flags() raises:
    var flags = List[String]()
    flags.append("--version")
    flags.append("-V")
    for flag in flags:
        var result = dispatch(args_list(flag))
        assert_equal(result[0], 0)
        assert_equal(result[1], "flare-routegen " + VERSION + "\n")
        assert_equal(result[2], "")


def test_generate_missing_output_exits_usage() raises:
    var result = dispatch(
        args_list(
            "generate",
            "--source",
            APP_SOURCE,
            "--package",
            APP_PACKAGE,
        )
    )
    assert_equal(result[0], 2)
    assert_true(result[2].find("requires --output") >= 0)


def test_check_missing_output_exits_usage() raises:
    var result = dispatch(
        args_list(
            "check",
            "--source",
            APP_SOURCE,
            "--package",
            APP_PACKAGE,
        )
    )
    assert_equal(result[0], 2)
    assert_true(result[2].find("requires --output") >= 0)


def test_dispatch_unknown_flag_exits_usage() raises:
    var result = dispatch(args_list("--unknown"))
    assert_equal(result[0], 2)
    assert_equal(result[1], "")
    assert_true(result[2].find("unknown option") >= 0)


def test_list_missing_flags_exits_usage() raises:
    var result = dispatch(args_list("list"))
    assert_equal(result[0], 2)
    assert_true(result[2].find("requires --source and --package") >= 0)


def test_list_success_for_app_basic() raises:
    var result = dispatch(
        args_list(
            "list",
            "--source",
            APP_SOURCE,
            "--package",
            APP_PACKAGE,
        )
    )
    assert_equal(result[0], 0)
    assert_true(
        result[1].find("GET\t/\tmy_app.views.home\thome\tviews/home.mojo:1")
        >= 0
    )
    assert_true(result[1].find("HEAD\t/users/:id") >= 0)
    assert_equal(result[2], "")


def test_list_exclude_skips_file() raises:
    var result = dispatch(
        args_list(
            "list",
            "--source",
            APP_SOURCE,
            "--package",
            APP_PACKAGE,
            "--exclude",
            "views/users.mojo",
        )
    )
    assert_equal(result[0], 0)
    assert_true(result[1].find("views/home.mojo") >= 0)
    assert_true(result[1].find("views/users.mojo") < 0)


def test_list_invalid_app_exits_semantic() raises:
    var result = dispatch(
        args_list(
            "list",
            "--source",
            "test/fixtures/app_invalid/src",
            "--package",
            APP_PACKAGE,
        )
    )
    assert_equal(result[0], 1)
    assert_equal(result[1], "")
    assert_true(result[2].find("[FRG") >= 0)


def test_generate_then_check_for_app_basic() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/_generated_routes.mojo"
        var generate = dispatch(
            args_list(
                "generate",
                "--source",
                APP_SOURCE,
                "--package",
                APP_PACKAGE,
                "--output",
                output,
            )
        )
        assert_equal(generate[0], 0)
        assert_true(Path(output).exists())
        var check = dispatch(
            args_list(
                "check",
                "--source",
                APP_SOURCE,
                "--package",
                APP_PACKAGE,
                "--output",
                output,
            )
        )
        assert_equal(check[0], 0)


def test_check_before_generate_exits_semantic() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        var result = dispatch(
            args_list(
                "check",
                "--source",
                APP_SOURCE,
                "--package",
                APP_PACKAGE,
                "--output",
                output,
            )
        )
        assert_equal(result[0], 1)
        assert_true(result[2].find("[FRG013]") >= 0)


def test_generate_unsafe_overwrite_exits_semantic() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        Path(output).write_text(
            "def user_code(req: String) -> String:\n    return req\n"
        )
        var result = dispatch(
            args_list(
                "generate",
                "--source",
                APP_SOURCE,
                "--package",
                APP_PACKAGE,
                "--output",
                output,
            )
        )
        assert_equal(result[0], 1)
        assert_true(result[2].find("[FRG012]") >= 0)


def test_generate_invalid_app_exits_semantic_without_write() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        var result = dispatch(
            args_list(
                "generate",
                "--source",
                "test/fixtures/app_invalid/src",
                "--package",
                APP_PACKAGE,
                "--output",
                output,
            )
        )
        assert_equal(result[0], 1)
        assert_true(result[2].find("[FRG") >= 0)
        assert_equal(Path(output).exists(), False)


def test_check_invalid_app_exits_semantic() raises:
    with TemporaryDirectory() as tmpdir:
        var output = tmpdir + "/routes.mojo"
        Path(output).write_text(
            GENERATED_MARKER_1 + "\n" + GENERATED_MARKER_2 + "\n"
        )
        var result = dispatch(
            args_list(
                "check",
                "--source",
                "test/fixtures/app_invalid/src",
                "--package",
                APP_PACKAGE,
                "--output",
                output,
            )
        )
        assert_equal(result[0], 1)
        assert_true(result[2].find("[FRG") >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
