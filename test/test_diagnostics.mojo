"""Grammar and diagnostic formatting tests."""

from std.testing import assert_equal, assert_true, TestSuite

from flare_routegen.diagnostics import (
    FRG001,
    FRG002,
    FRG003,
    FRG004,
    FRG008,
    make_diagnostic,
)
from flare_routegen.discover import discover_routes
from flare_routegen.grammar import parse_directive_line


def test_parse_malformed_directive() raises:
    var parsed = parse_directive_line("# @flare.route", "x.mojo", 1, 1)
    assert_true(parsed[1])
    assert_equal(parsed[1].value().code, FRG001)


def test_parse_unsupported_method() raises:
    var parsed = parse_directive_line("# @flare.route FOO /bad", "x.mojo", 2, 1)
    assert_true(parsed[1])
    assert_equal(parsed[1].value().code, FRG002)


def test_parse_missing_path() raises:
    var parsed = parse_directive_line("# @flare.route GET", "x.mojo", 3, 1)
    assert_true(parsed[1])
    assert_equal(parsed[1].value().code, FRG003)


def test_parse_quoted_path() raises:
    var parsed = parse_directive_line(
        '# @flare.route GET "/quoted"', "x.mojo", 4, 1
    )
    assert_true(parsed[1])
    assert_equal(parsed[1].value().code, FRG003)


def test_parse_trailing_token() raises:
    var parsed = parse_directive_line(
        "# @flare.route GET /extra token", "x.mojo", 5, 1
    )
    assert_true(parsed[1])
    assert_equal(parsed[1].value().code, FRG004)


def test_parse_valid_directive() raises:
    var parsed = parse_directive_line(
        "# @flare.route GET /users/:id", "x.mojo", 6, 1
    )
    assert_true(parsed[0])
    assert_equal(parsed[0].value().method, "GET")
    assert_equal(parsed[0].value().normalized_path, "/users/:id")


def test_diagnostic_format_includes_code_and_location() raises:
    var diagnostic = make_diagnostic(
        FRG001,
        "views/home.mojo",
        7,
        1,
        "malformed route directive",
        "use `# @flare.route <METHOD> <PATH>`",
    )
    var text = diagnostic.format()
    assert_true(text.find("views/home.mojo:7:1") >= 0)
    assert_true(text.find("[FRG001]") >= 0)
    assert_true(text.find("malformed route directive") >= 0)


def test_discover_duplicate_route_reports_frg008() raises:
    var result = discover_routes(
        "test/fixtures/app_invalid/src",
        "my_app",
        List[String](),
    )
    assert_equal(len(result.routes), 0)
    var found = False
    for diagnostic in result.diagnostics:
        if diagnostic.code == FRG008:
            found = True
    assert_true(found)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
