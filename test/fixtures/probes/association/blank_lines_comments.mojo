# Expected: bind directive to `show_user` despite blank lines and comments.

# @flare.route GET /users/:id

# ordinary comment between directive and handler


def show_user(req: String) -> String:
    return req
