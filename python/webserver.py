import web
from web.httpserver import StaticMiddleware


def initWebServer():
    urls = (
    '/', 'index'
    )

    app = web.application(urls, globals())
    web.httpserver.runsimple(app.wsgifunc(lambda app: StaticMiddleware(app, '/static/')), ("0.0.0.0", 8080))

class index:
    def GET(self):
        return "Hello, world!"
