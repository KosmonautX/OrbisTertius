BASE_ROUTE = "orb"


def register_routes(api, app, root="api"):
    from .controller import api as orb_api

    api.add_namespace(orb_api, path=f"/{root}/{BASE_ROUTE}")
