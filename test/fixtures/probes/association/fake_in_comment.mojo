# Expected: ignore non-directive comment text that resembles a directive.

# not a directive: @flare.route GET /fake

# @flare.route GET /real


def real(req: String) -> String:
    return req
