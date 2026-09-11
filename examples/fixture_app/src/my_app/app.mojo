"""Application handler assembly for the fixture.

Production apps nest stock middleware (`RequestId`, `Logger`, `Cors`, ...)
around this handler; flare-routegen does not emit those wrappers.
"""

from flare.http import ComptimeRouter
from my_app._generated_routes import ROUTES


def make_router() -> ComptimeRouter[ROUTES]:
    return ComptimeRouter[ROUTES]()
