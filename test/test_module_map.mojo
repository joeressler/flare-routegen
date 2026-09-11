"""Module-path mapping and alias validation tests."""

from std.testing import assert_equal, assert_true, TestSuite

from flare_routegen.diagnostics import Diagnostic, FRG009, FRG010, FRG011
from flare_routegen.discover import discover_routes
from flare_routegen.models import DiscoveredRoute
from flare_routegen.module_map import (
    MappedSourceFile,
    handler_import_alias,
    handler_wrapper_name,
    module_path_for_file,
    validate_handler_aliases,
    validate_mapped_files,
)


def diagnostics_contain_code(
    diagnostics: List[Diagnostic], code: String
) -> Bool:
    for diagnostic in diagnostics:
        if diagnostic.code == code:
            return True
    return False


def test_module_path_for_nested_file() raises:
    assert_equal(
        module_path_for_file("my_app", "views/home.mojo"),
        "my_app.views.home",
    )


def test_module_path_for_init_strips_suffix() raises:
    assert_equal(module_path_for_file("my_app", "__init__.mojo"), "my_app")
    assert_equal(
        module_path_for_file("my_app", "views/__init__.mojo"),
        "my_app.views",
    )


def test_invalid_segment_reports_frg010() raises:
    var mapped = List[MappedSourceFile]()
    mapped.append(MappedSourceFile("bad-name.mojo", "my_app.bad-name"))
    var diagnostics = validate_mapped_files(mapped)
    assert_true(len(diagnostics) > 0)
    assert_equal(diagnostics[0].code, FRG010)


def test_discover_invalid_segment_reports_frg010() raises:
    var result = discover_routes(
        "test/fixtures/module_map/invalid_segment/src",
        "my_app",
        List[String](),
    )
    assert_equal(len(result.routes), 0)
    assert_true(diagnostics_contain_code(result.diagnostics, FRG010))


def test_colliding_files_report_frg009() raises:
    var mapped = List[MappedSourceFile]()
    mapped.append(MappedSourceFile("foo.mojo", "my_app.foo"))
    mapped.append(MappedSourceFile("foo/__init__.mojo", "my_app.foo"))
    var diagnostics = validate_mapped_files(mapped)
    assert_true(len(diagnostics) >= 2)
    assert_true(diagnostics_contain_code(diagnostics, FRG009))


def test_discover_colliding_files_report_frg009() raises:
    var result = discover_routes(
        "test/fixtures/module_map/collision_frg009/src",
        "my_app",
        List[String](),
    )
    assert_equal(len(result.routes), 0)
    assert_true(diagnostics_contain_code(result.diagnostics, FRG009))


def test_alias_collision_reports_frg011() raises:
    var routes = List[DiscoveredRoute]()
    routes.append(
        DiscoveredRoute(
            "GET",
            "/a",
            "/a",
            "c_d",
            "a.b",
            "a/b.mojo",
            1,
            1,
            2,
            1,
        )
    )
    routes.append(
        DiscoveredRoute(
            "GET",
            "/b",
            "/b",
            "b_c_d",
            "a",
            "a.mojo",
            1,
            1,
            2,
            1,
        )
    )
    var diagnostics = validate_handler_aliases(routes)
    assert_true(len(diagnostics) >= 2)
    assert_true(diagnostics_contain_code(diagnostics, FRG011))


def test_stable_alias_and_wrapper_names() raises:
    assert_equal(
        handler_import_alias("my_app.views.home", "home"),
        "_frg_my_app_views_home_home",
    )
    assert_equal(
        handler_wrapper_name("my_app.views.home", "home"),
        "_frg_wrap_my_app_views_home_home",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
