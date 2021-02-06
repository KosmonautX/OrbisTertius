import time

def register_routes(api, app, root="api"):
    from app.widget import register_routes as attach_widget
    from app.fizz import register_routes as attach_fizz
    from app.other_api import register_routes as attach_other_api
    from app.third_party.app import create_bp
    from app.orb import register_routes as attach_orb
    import time
    # Add routes
    attach_widget(api, app)
    attach_fizz(api, app)
    attach_other_api(api, app)
    attach_orb(api, app)
    app.register_blueprint(create_bp(), url_prefix="/third_party")
