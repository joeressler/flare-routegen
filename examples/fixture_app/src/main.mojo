"""Runnable fixture entrypoint. Instantiates ComptimeRouter without binding a port."""

from flare.http import Request
from my_app.app import make_router


def main() raises:
    var r = make_router()
    var resp = r.serve(Request.test_get("/"))
    print(resp.text())
