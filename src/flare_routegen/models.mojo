"""Shared data models for flare-routegen."""

from flare_routegen.diagnostics import Diagnostic

comptime HANDLER_KIND_FUNCTION = "function"
comptime HANDLER_KIND_STRUCT = "struct"


@fieldwise_init
struct DiscoveredRoute(Copyable, Movable):
    """A validated route discovered from a source file."""

    var method: String
    var path: String
    var normalized_path: String
    var handler_symbol: String
    var module_path: String
    var source_path: String
    var directive_line: Int
    var directive_column: Int
    var handler_line: Int
    var handler_column: Int
    var handler_kind: String

    def format_list_row(self) -> String:
        return (
            self.method
            + "\t"
            + self.path
            + "\t"
            + self.module_path
            + "\t"
            + self.handler_symbol
            + "\t"
            + self.source_path
            + ":"
            + String(self.directive_line)
        )


@fieldwise_init
struct PendingDirective(Copyable, Movable):
    """Directive waiting for the next top-level handler."""

    var method: String
    var path: String
    var normalized_path: String
    var directive_line: Int
    var directive_column: Int


@fieldwise_init
struct ScanFileResult(Copyable, Movable):
    """Routes and diagnostics produced by scanning one file."""

    var routes: List[DiscoveredRoute]
    var diagnostics: List[Diagnostic]


@fieldwise_init
struct DiscoverResult(Copyable, Movable):
    """Aggregate discovery output for a package root."""

    var routes: List[DiscoveredRoute]
    var diagnostics: List[Diagnostic]
