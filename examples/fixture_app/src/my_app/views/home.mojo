from flare.http import Request, Response, ok

# @flare.route GET /


def home(req: Request) raises -> Response:
    return ok("home")
