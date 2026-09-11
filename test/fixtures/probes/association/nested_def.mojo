# Expected: bind directive to top-level `outer` (GET /nested).

# @flare.route GET /nested


def outer(req: String) -> String:
    def inner(req: String) -> String:
        return req

    return req
