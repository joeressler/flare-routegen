# Expected: bind directive to `GetUser` with `@fieldwise_init` between.

# @flare.route GET /users/:id


@fieldwise_init
struct GetUser(Copyable, Defaultable, Handler, Movable):
    var id: Int
