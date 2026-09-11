"""Repository bootstrap and pin smoke tests."""

from std.os import path
from std.testing import assert_equal, assert_true, TestSuite

from flare_routegen.version import (
    FLARE_PIN_CI,
    FLARE_RANGE,
    MOJO_PIN_CI,
    MOJO_RANGE,
    PIXI_PIN_CI,
    VERSION,
)

comptime FIXTURE_ROOT = "test/fixtures/probes"


def test_version_constant() raises:
    assert_equal(VERSION, "0.1.0")


def test_pin_constants_match_spec() raises:
    assert_equal(MOJO_PIN_CI, "1.0.0")
    assert_equal(MOJO_RANGE, ">=1.0.0,<1.1.0")
    assert_equal(FLARE_PIN_CI, "v0.10.0")
    assert_equal(FLARE_RANGE, ">=0.10.0,<0.11.0")
    assert_equal(PIXI_PIN_CI, "0.70.2")


def test_probe_fixture_corpus_exists() raises:
    var expected = List[String]()
    expected.append(FIXTURE_ROOT + "/README.md")
    expected.append(FIXTURE_ROOT + "/association/valid_basic.mojo")
    expected.append(FIXTURE_ROOT + "/association/blank_lines_comments.mojo")
    expected.append(FIXTURE_ROOT + "/association/decorator_between.mojo")
    expected.append(FIXTURE_ROOT + "/association/multiline_signature.mojo")
    expected.append(FIXTURE_ROOT + "/association/multiple_directives.mojo")
    expected.append(FIXTURE_ROOT + "/association/fake_in_string.mojo")
    expected.append(FIXTURE_ROOT + "/association/fake_in_comment.mojo")
    expected.append(FIXTURE_ROOT + "/association/orphan_statement.mojo")
    expected.append(FIXTURE_ROOT + "/association/nested_def.mojo")
    expected.append(FIXTURE_ROOT + "/association/indented_directive.mojo")
    expected.append("test/fixtures/app_basic/src/my_app/views/home.mojo")
    expected.append("test/fixtures/app_invalid/src/my_app/malformed.mojo")
    expected.append(
        FIXTURE_ROOT + "/determinism/tree_a/src/my_app/views/home.mojo"
    )
    expected.append(
        FIXTURE_ROOT + "/determinism/tree_a/src/my_app/views/users.mojo"
    )
    expected.append(
        FIXTURE_ROOT + "/determinism/tree_b/src/my_app/views/users.mojo"
    )
    expected.append(
        FIXTURE_ROOT + "/determinism/tree_b/src/my_app/views/home.mojo"
    )

    for fixture_path in expected:
        assert_true(
            path.exists(fixture_path),
            msg="missing probe fixture: " + fixture_path,
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
