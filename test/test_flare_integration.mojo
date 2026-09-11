"""Flare compile and in-process dispatch tests for the fixture app."""

from std.testing import assert_equal, assert_true, TestSuite

from flare.http import Method, Request
from flare_routegen.output import check_routes
from my_app.app import make_router

comptime FIXTURE_SOURCE = "examples/fixture_app/src"
comptime FIXTURE_PACKAGE = "my_app"
comptime FIXTURE_OUTPUT = (
    "examples/fixture_app/src/my_app/_generated_routes.mojo"
)


def test_committed_generated_routes_are_fresh() raises:
    var diagnostics = check_routes(
        FIXTURE_SOURCE,
        FIXTURE_PACKAGE,
        FIXTURE_OUTPUT,
        List[String](),
    )
    assert_equal(len(diagnostics), 0)


def test_comptime_router_compiles_from_generated_routes() raises:
    var router = make_router()
    var resp = router.serve(Request.test_get("/"))
    assert_equal(resp.status, 200)
    assert_true(resp.text().find("home") >= 0)


def test_cross_module_user_route_dispatches() raises:
    var router = make_router()
    var resp = router.serve(Request.test_get("/users/42"))
    assert_equal(resp.status, 200)
    assert_true(resp.text().find("42") >= 0)


def test_repeated_handler_head_dispatches() raises:
    var router = make_router()
    var resp = router.serve(Request(method=Method.HEAD, url="/users/42"))
    assert_equal(resp.status, 200)


def test_extracted_path_int_rejects_non_integer() raises:
    var router = make_router()
    var resp = router.serve(Request.test_get("/users/abc"))
    assert_equal(resp.status, 400)


def test_unknown_path_returns_404() raises:
    var router = make_router()
    var resp = router.serve(Request.test_get("/nope"))
    assert_equal(resp.status, 404)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
