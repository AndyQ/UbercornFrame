import asyncio
import websockets
import threading
from time import sleep
from queue import Queue
from webserver import initWebServer

q = Queue()

async def handler(websocket, path):
    while True:
        message = await websocket.recv()
        q.put( message )
        await websocket.send("OK")

def initSocket():
    asyncio.set_event_loop(asyncio.new_event_loop())

    print( "STARTING SOCKET.....")
    start_server = websockets.serve(handler, '0.0.0.0', 8765)

    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()


def startWebSocket():
    wst = threading.Thread(target=initSocket)
    wst.daemon = True
    wst.start()


def startWebServer():
    wst = threading.Thread(target=initWebServer)
    wst.daemon = True
    wst.start()

