"""Scanner and association fixture tests."""

from std.pathlib import Path
from std.testing import assert_equal, assert_true, TestSuite

from flare_routegen.diagnostics import FRG005, FRG006, FRG007
from flare_routegen.discover import discover_routes
from flare_routegen.module_map import module_path_for_file
from flare_routegen.models import (
    HANDLER_KIND_FUNCTION,
    HANDLER_KIND_STRUCT,
    ScanFileResult,
)
from flare_routegen.scan import scan_file_content

comptime PROBE_ROOT = "test/fixtures/probes/association"


def read_fixture(name: String) raises -> String:
    return Path(PROBE_ROOT + "/" + name).read_text()


def scan_fixture(name: String) raises -> ScanFileResult:
    var source_path = name
    var module_path = module_path_for_file("probe", source_path)
    return scan_file_content(read_fixture(name), source_path, module_path)


def test_valid_basic_binds_home() raises:
    var result = scan_fixture("valid_basic.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].method, "GET")
    assert_equal(result.routes[0].path, "/")
    assert_equal(result.routes[0].handler_symbol, "home")
    assert_equal(result.routes[0].handler_kind, HANDLER_KIND_FUNCTION)


def test_blank_lines_and_comments_bind() raises:
    var result = scan_fixture("blank_lines_comments.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].handler_symbol, "show_user")


def test_decorator_between_binds() raises:
    var result = scan_fixture("decorator_between.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].handler_symbol, "decorated")


def test_multiline_signature_binds() raises:
    var result = scan_fixture("multiline_signature.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].handler_symbol, "multiline")


def test_multiple_directives_bind_twice() raises:
    var result = scan_fixture("multiple_directives.mojo")
    assert_equal(len(result.routes), 2)
    assert_equal(result.routes[0].method, "GET")
    assert_equal(result.routes[1].method, "HEAD")


def test_fake_in_string_ignored() raises:
    var result = scan_fixture("fake_in_string.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].path, "/real")
    assert_equal(result.routes[0].handler_symbol, "real")


def test_fake_in_comment_ignored() raises:
    var result = scan_fixture("fake_in_comment.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].path, "/real")


def test_orphan_statement_reports_frg006() raises:
    var result = scan_fixture("orphan_statement.mojo")
    assert_equal(len(result.routes), 0)
    assert_true(len(result.diagnostics) >= 1)
    assert_equal(result.diagnostics[0].code, FRG006)


def test_nested_def_binds_outer() raises:
    var result = scan_fixture("nested_def.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].handler_symbol, "outer")


def test_indented_directive_reports_frg007() raises:
    var result = scan_fixture("indented_directive.mojo")
    assert_equal(len(result.routes), 0)
    assert_true(len(result.diagnostics) >= 1)
    assert_equal(result.diagnostics[0].code, FRG007)


def test_struct_handler_binds_get_user() raises:
    var result = scan_fixture("struct_handler.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].method, "GET")
    assert_equal(result.routes[0].path, "/users/:id")
    assert_equal(result.routes[0].handler_symbol, "GetUser")
    assert_equal(result.routes[0].handler_kind, HANDLER_KIND_STRUCT)


def test_fieldwise_init_struct_binds() raises:
    var result = scan_fixture("fieldwise_init_struct.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].handler_symbol, "GetUser")
    assert_equal(result.routes[0].handler_kind, HANDLER_KIND_STRUCT)


def test_multiple_directives_struct_bind_twice() raises:
    var result = scan_fixture("multiple_directives_struct.mojo")
    assert_equal(len(result.routes), 2)
    assert_equal(result.routes[0].method, "GET")
    assert_equal(result.routes[1].method, "HEAD")
    assert_equal(result.routes[0].handler_symbol, "GetUser")
    assert_equal(result.routes[0].handler_kind, HANDLER_KIND_STRUCT)
    assert_equal(result.routes[1].handler_kind, HANDLER_KIND_STRUCT)


def test_nested_struct_binds_outer() raises:
    var result = scan_fixture("nested_struct.mojo")
    assert_equal(len(result.routes), 1)
    assert_equal(result.routes[0].handler_symbol, "Outer")
    assert_equal(result.routes[0].handler_kind, HANDLER_KIND_STRUCT)


def test_duplicate_on_handler_reports_frg005() raises:
    var content = (
        "# @flare.route GET /dup\n"
        + "# @flare.route GET /dup\n\n"
        + "def handler(req: String) -> String:\n"
        + "    return req\n"
    )
    var result = scan_file_content(content, "dup.mojo", "probe.dup")
    assert_equal(len(result.routes), 1)
    assert_true(len(result.diagnostics) >= 1)
    assert_equal(result.diagnostics[0].code, FRG005)


def test_discover_app_basic_stable_order() raises:
    var result = discover_routes(
        "test/fixtures/app_basic/src",
        "my_app",
        List[String](),
    )
    assert_equal(len(result.diagnostics), 0)
    assert_equal(len(result.routes), 3)
    assert_equal(result.routes[0].path, "/")
    assert_equal(result.routes[1].method, "GET")
    assert_equal(result.routes[2].method, "HEAD")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
