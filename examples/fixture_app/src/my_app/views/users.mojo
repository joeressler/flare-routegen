from flare.http import Handler, PathInt, Request, Response, ok

# @flare.route GET /users/:id
# @flare.route HEAD /users/:id


@fieldwise_init
struct GetUser(Copyable, Defaultable, Handler, Movable):
    var id: PathInt["id"]

    def __init__(out self):
        self.id = PathInt["id"]()

    def serve(self, req: Request) raises -> Response:
        return ok("user=" + String(self.id.value))
