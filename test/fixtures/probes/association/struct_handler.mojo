# Expected: bind directive to `GetUser` (GET /users/:id).

# @flare.route GET /users/:id


struct GetUser(Copyable, Defaultable, Handler, Movable):
    var id: Int
