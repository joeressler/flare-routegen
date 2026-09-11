# Expected: ignore fake directive text inside a string literal.

comptime MESSAGE = "# @flare.route GET /fake"

# @flare.route GET /real


def real(req: String) -> String:
    return req
