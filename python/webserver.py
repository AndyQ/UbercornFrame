import glob
from time import sleep
import threading
from queue import Queue
import web
from web.httpserver import StaticMiddleware

render = web.template.render('templates/')
dataQueue = None

def startWebServer( queue ):
    global dataQueue
    dataQueue = queue
    wst = threading.Thread(target=initWebServer)
    wst.daemon = True
    wst.start()


def initWebServer():
    urls = (
    '/', 'index',
    '/play/(.*)', 'Play',
    '/stop', 'Stop',
    '/restart', 'Restart'

    )

    app = web.application(urls, globals())
    web.httpserver.runsimple(app.wsgifunc(lambda app: StaticMiddleware(app, '/images/')), ("0.0.0.0", 8080))

class index:
    def GET(self):
        # Get list of gif files in images folder
        files = glob.glob('./images/*.gif')
        files = [ file[9:] for file in files ]
        files.sort()
        return render.index(files)

class Play:
    def GET(self, file):
        global dataQueue
        dataQueue.put( "PLAY:{}".format(file) )
        return "OK"

class Stop:
    def GET(self):
        global dataQueue
        dataQueue.put( "STOP" )
        return "OK"

class Restart:
    def GET(self):
        global dataQueue
        dataQueue.put( "RESTART" )
        return "OK"

if __name__ == '__main__':
    q = Queue()
    startWebServer(q)

    while True:
        sleep(100)
