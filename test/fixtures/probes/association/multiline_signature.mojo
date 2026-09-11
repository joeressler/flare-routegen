# Expected: bind directive to `multiline` even when the signature spans lines.

# @flare.route PUT /profile


def multiline(
    req: String,
    extra: String,
) -> String:
    return req
