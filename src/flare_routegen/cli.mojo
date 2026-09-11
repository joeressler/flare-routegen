"""CLI entrypoint for flare-routegen."""

from std.sys import argv, exit, stderr

from flare_routegen.discover import (
    discover_routes,
    format_diagnostics_output,
    format_list_output,
)
from flare_routegen.output import check_routes, generate_routes
from flare_routegen.version import VERSION

comptime EXIT_SUCCESS = 0
comptime EXIT_SEMANTIC = 1
comptime EXIT_USAGE = 2
comptime EXIT_TOOLING = 3


@fieldwise_init
struct CommandOptions(Copyable, Movable):
    """Parsed CLI options for list/generate/check."""

    var show_help: Bool
    var source: String
    var package_name: String
    var output: String
    var excludes: List[String]
    var error_message: String


def help_text() -> String:
    return (
        "flare-routegen — generate Flare route registrations from Mojo comment"
        " directives\n\nUsage:\n  flare-routegen generate --source <dir>"
        " --package <pkg> --output <file> [--exclude <glob> ...]\n "
        " flare-routegen check    --source <dir> --package <pkg> --output"
        " <file> [--exclude <glob> ...]\n  flare-routegen list     --source"
        " <dir> --package <pkg> [--exclude <glob> ...]\n  flare-routegen"
        " --help\n  flare-routegen --version\n\nOptions:\n  --source <dir>    "
        " Source root to scan\n  --package <pkg>    Package name for"
        " module-path derivation\n  --output <file>    Generated routes output"
        " file (generate/check only)\n  --exclude <glob>   Glob to skip during"
        " discovery (repeatable)\n  -h, --help         Show this help message\n"
        "  -V, --version      Show version information\n\nList output"
        " columns:\n "
        " METHOD<TAB>PATH<TAB>MODULE<TAB>HANDLER<TAB>SOURCE:LINE\n\nExit"
        " codes:\n  0  success\n  1  semantic failure\n  2  CLI usage error\n "
        " 3  tooling/runtime failure\n"
    )


def version_text() -> String:
    return "flare-routegen " + VERSION + "\n"


def is_help_flag(arg: String) -> Bool:
    return arg == "--help" or arg == "-h"


def is_version_flag(arg: String) -> Bool:
    return arg == "--version" or arg == "-V"


def usage_error_message(message: String) -> String:
    return message + "\nRun flare-routegen --help for usage.\n"


def empty_command_options() -> CommandOptions:
    return CommandOptions(
        False,
        "",
        "",
        "",
        List[String](),
        "",
    )


def parse_command_options(
    args: List[String],
    require_output: Bool,
    allow_output: Bool,
    command_name: String,
) -> CommandOptions:
    var options = empty_command_options()
    var index = 1
    while index < len(args):
        var arg = args[index]
        if is_help_flag(arg):
            options.show_help = True
            return options.copy()
        if arg == "--source":
            index += 1
            if index >= len(args):
                options.error_message = usage_error_message(
                    "error: missing value for --source"
                )
                return options.copy()
            options.source = args[index]
            index += 1
            continue
        if arg == "--package":
            index += 1
            if index >= len(args):
                options.error_message = usage_error_message(
                    "error: missing value for --package"
                )
                return options.copy()
            options.package_name = args[index]
            index += 1
            continue
        if arg == "--exclude":
            index += 1
            if index >= len(args):
                options.error_message = usage_error_message(
                    "error: missing value for --exclude"
                )
                return options.copy()
            options.excludes.append(args[index])
            index += 1
            continue
        if arg == "--output":
            if not allow_output:
                options.error_message = usage_error_message(
                    "error: --output is not valid for " + command_name
                )
                return options.copy()
            index += 1
            if index >= len(args):
                options.error_message = usage_error_message(
                    "error: missing value for --output"
                )
                return options.copy()
            options.output = args[index]
            index += 1
            continue
        options.error_message = usage_error_message(
            "error: unknown option for " + command_name + ": " + arg
        )
        return options.copy()

    if options.source == "" or options.package_name == "":
        options.error_message = usage_error_message(
            "error: " + command_name + " requires --source and --package"
        )
        return options.copy()

    if require_output and options.output == "":
        options.error_message = usage_error_message(
            "error: " + command_name + " requires --output"
        )
        return options.copy()

    return options.copy()


def run_list(args: List[String]) -> Tuple[Int, String, String]:
    var parsed = parse_command_options(args, False, False, "list")
    if parsed.error_message:
        return (EXIT_USAGE, "", parsed.error_message)
    if parsed.show_help:
        return (EXIT_SUCCESS, help_text(), "")

    try:
        var result = discover_routes(
            parsed.source, parsed.package_name, parsed.excludes
        )
        if len(result.diagnostics) > 0:
            return (
                EXIT_SEMANTIC,
                "",
                format_diagnostics_output(result.diagnostics),
            )
        return (EXIT_SUCCESS, format_list_output(result), "")
    except e:
        return (EXIT_TOOLING, "", usage_error_message("error: " + String(e)))


def run_generate(args: List[String]) -> Tuple[Int, String, String]:
    var parsed = parse_command_options(args, True, True, "generate")
    if parsed.error_message:
        return (EXIT_USAGE, "", parsed.error_message)
    if parsed.show_help:
        return (EXIT_SUCCESS, help_text(), "")

    try:
        var diagnostics = generate_routes(
            parsed.source,
            parsed.package_name,
            parsed.output,
            parsed.excludes,
        )
        if len(diagnostics) > 0:
            return (
                EXIT_SEMANTIC,
                "",
                format_diagnostics_output(diagnostics),
            )
        return (EXIT_SUCCESS, "", "")
    except e:
        return (EXIT_TOOLING, "", usage_error_message("error: " + String(e)))


def run_check(args: List[String]) -> Tuple[Int, String, String]:
    var parsed = parse_command_options(args, True, True, "check")
    if parsed.error_message:
        return (EXIT_USAGE, "", parsed.error_message)
    if parsed.show_help:
        return (EXIT_SUCCESS, help_text(), "")

    try:
        var diagnostics = check_routes(
            parsed.source,
            parsed.package_name,
            parsed.output,
            parsed.excludes,
        )
        if len(diagnostics) > 0:
            return (
                EXIT_SEMANTIC,
                "",
                format_diagnostics_output(diagnostics),
            )
        return (EXIT_SUCCESS, "", "")
    except e:
        return (EXIT_TOOLING, "", usage_error_message("error: " + String(e)))


def dispatch(args: List[String]) -> Tuple[Int, String, String]:
    """Route argv to help, version, list, or usage errors."""
    if len(args) == 0:
        return (EXIT_SUCCESS, help_text(), "")

    var first = args[0]
    if is_help_flag(first):
        return (EXIT_SUCCESS, help_text(), "")

    if is_version_flag(first):
        return (EXIT_SUCCESS, version_text(), "")

    if first == "list":
        return run_list(args)

    if first == "generate":
        return run_generate(args)

    if first == "check":
        return run_check(args)

    if first.startswith("-"):
        return (
            EXIT_USAGE,
            "",
            usage_error_message("error: unknown option: " + first),
        )

    return (
        EXIT_USAGE,
        "",
        usage_error_message("error: unknown command: " + first),
    )


def run_cli() raises -> None:
    """Parse argv, dispatch, and exit with the CLI status code."""
    var args = List[String]()
    var raw_args = argv()
    for i in range(1, len(raw_args)):
        var arg = String(raw_args[i])
        if arg == "--":
            continue
        args.append(arg)

    var result = dispatch(args)
    var code = result[0]
    var stdout_text = result[1]
    var stderr_text = result[2]

    if stdout_text:
        print(stdout_text, end="")
    if stderr_text:
        var err = stderr
        err.write(stderr_text)

    exit(code)
