"""Diagnostic codes and formatting for flare-routegen."""

comptime FRG001 = "FRG001"
comptime FRG002 = "FRG002"
comptime FRG003 = "FRG003"
comptime FRG004 = "FRG004"
comptime FRG005 = "FRG005"
comptime FRG006 = "FRG006"
comptime FRG007 = "FRG007"
comptime FRG008 = "FRG008"
comptime FRG009 = "FRG009"
comptime FRG010 = "FRG010"
comptime FRG011 = "FRG011"
comptime FRG012 = "FRG012"
comptime FRG013 = "FRG013"
comptime FRG014 = "FRG014"
comptime FRG015 = "FRG015"
comptime FRG017 = "FRG017"
comptime FRG018 = "FRG018"


@fieldwise_init
struct Diagnostic(Copyable, Movable):
    """A single scanner or discovery diagnostic."""

    var code: String
    var source_path: String
    var line: Int
    var column: Int
    var message: String
    var correction: String

    def format(self) -> String:
        var text = (
            self.source_path
            + ":"
            + String(self.line)
            + ":"
            + String(self.column)
            + ": error: ["
            + self.code
            + "] "
            + self.message
        )
        if self.correction:
            return text + " " + self.correction
        return text


def make_diagnostic(
    code: String,
    source_path: String,
    line: Int,
    column: Int,
    message: String,
    correction: String = "",
) -> Diagnostic:
    return Diagnostic(code, source_path, line, column, message, correction)


def sort_key(d: Diagnostic) -> Tuple[String, Int, Int, String]:
    return (d.source_path, d.line, d.column, d.code)
