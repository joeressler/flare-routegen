# Expected: bind directive to top-level `Outer` (GET /nested).

# @flare.route GET /nested


struct Outer:
    struct Inner:
        var x: Int
