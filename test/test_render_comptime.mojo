"""Compile-time renderer golden and determinism tests."""

from std.pathlib import Path
from std.testing import assert_equal, assert_true, TestSuite

from flare_routegen.discover import discover_routes
from flare_routegen.models import (
    DiscoveredRoute,
    HANDLER_KIND_FUNCTION,
    HANDLER_KIND_STRUCT,
)
from flare_routegen.module_map import handler_wrapper_name
from flare_routegen.render_comptime import render_comptime
from flare_routegen.render_runtime import render_runtime
from flare_routegen.text_util import text_len, text_slice

comptime GOLDEN_APP_BASIC = "test/fixtures/golden/app_basic.golden"


def read_fixture(path: String) raises -> String:
    return Path(path).read_text()


def count_occurrences(text: String, needle: String) -> Int:
    var count = 0
    var start = 0
    var total_len = text_len(text)
    var needle_len = text_len(needle)
    while start < total_len:
        var index = text_slice(text, start, total_len).find(needle)
        if index < 0:
            break
        count += 1
        start += index + needle_len
    return count


def test_render_app_basic_matches_golden() raises:
    var discovered = discover_routes(
        "test/fixtures/app_basic/src",
        "my_app",
        List[String](),
    )
    assert_equal(len(discovered.diagnostics), 0)
    var rendered = render_comptime(discovered.routes)
    assert_equal(len(rendered[1]), 0)
    assert_equal(rendered[0], read_fixture(GOLDEN_APP_BASIC))


def test_render_is_stable_when_input_reversed() raises:
    var discovered = discover_routes(
        "test/fixtures/app_basic/src",
        "my_app",
        List[String](),
    )
    var reversed_routes = List[DiscoveredRoute]()
    var index = len(discovered.routes) - 1
    while index >= 0:
        reversed_routes.append(discovered.routes[index].copy())
        index -= 1

    var forward = render_comptime(discovered.routes)
    var backward = render_comptime(reversed_routes)
    assert_equal(forward[0], backward[0])


def test_shared_handler_emits_one_wrapper() raises:
    var discovered = discover_routes(
        "test/fixtures/app_basic/src",
        "my_app",
        List[String](),
    )
    var rendered = render_comptime(discovered.routes)
    var wrapper = handler_wrapper_name("my_app.views.users", "show_user")
    assert_equal(count_occurrences(rendered[0], "def " + wrapper), 1)
    assert_true(rendered[0].find("def " + wrapper) >= 0)


def make_route(
    method: String,
    path: String,
    handler_symbol: String,
    module_path: String,
    source_path: String,
    handler_kind: String,
) -> DiscoveredRoute:
    return DiscoveredRoute(
        method,
        path,
        path,
        handler_symbol,
        module_path,
        source_path,
        1,
        1,
        2,
        1,
        handler_kind,
    )


def test_render_struct_handler_uses_extracted() raises:
    var routes = List[DiscoveredRoute]()
    routes.append(
        make_route(
            "GET",
            "/",
            "home",
            "my_app.views.home",
            "views/home.mojo",
            HANDLER_KIND_FUNCTION,
        )
    )
    routes.append(
        make_route(
            "GET",
            "/users/:id",
            "GetUser",
            "my_app.views.users",
            "views/users.mojo",
            HANDLER_KIND_STRUCT,
        )
    )
    var rendered = render_comptime(routes)
    assert_equal(len(rendered[1]), 0)
    var text = rendered[0]
    assert_true(text.find("Extracted,") >= 0)
    assert_true(
        text.find(
            "return Extracted[_frg_my_app_views_users_GetUser]().serve(req)"
        )
        >= 0
    )
    assert_true(text.find("return _frg_my_app_views_home_home(req)") >= 0)


def test_render_runtime_struct_uses_extracted_registration() raises:
    var routes = List[DiscoveredRoute]()
    routes.append(
        make_route(
            "GET",
            "/",
            "home",
            "my_app.views.home",
            "views/home.mojo",
            HANDLER_KIND_FUNCTION,
        )
    )
    routes.append(
        make_route(
            "GET",
            "/users/:id",
            "GetUser",
            "my_app.views.users",
            "views/users.mojo",
            HANDLER_KIND_STRUCT,
        )
    )
    routes.append(
        make_route(
            "HEAD",
            "/users/:id",
            "GetUser",
            "my_app.views.users",
            "views/users.mojo",
            HANDLER_KIND_STRUCT,
        )
    )
    var rendered = render_runtime(routes)
    assert_equal(len(rendered[1]), 0)
    var text = rendered[0]
    var struct_wrapper = handler_wrapper_name("my_app.views.users", "GetUser")
    assert_equal(count_occurrences(text, "def " + struct_wrapper), 0)
    assert_true(text.find("from flare.http import Extracted,") >= 0)
    assert_true(
        text.find(
            "router.get[Extracted[_frg_my_app_views_users_GetUser]]("
            + '"/users/:id", Extracted[_frg_my_app_views_users_GetUser]())'
        )
        >= 0
    )
    assert_true(
        text.find(
            "router.head[Extracted[_frg_my_app_views_users_GetUser]]("
            + '"/users/:id", Extracted[_frg_my_app_views_users_GetUser]())'
        )
        >= 0
    )
    assert_true(text.find("return _frg_my_app_views_home_home(req)") >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
