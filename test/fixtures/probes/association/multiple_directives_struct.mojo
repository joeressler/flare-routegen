# Expected: bind both directives to `GetUser`.

# @flare.route GET /users/:id
# @flare.route HEAD /users/:id


struct GetUser(Copyable, Defaultable, Handler, Movable):
    var id: Int
