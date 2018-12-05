import asyncio
import websockets
import threading
from time import sleep
from queue import Queue
from webserver import initWebServer

dataQueue = None

async def handler(websocket, path):
    global dataQueue
    try:
        while True:
            message = await websocket.recv()
            dataQueue.put( message )
            await websocket.send("OK")
    except:
        print( "Socket closed!" )

def initSocket():
    asyncio.set_event_loop(asyncio.new_event_loop())

    print( "STARTING SOCKET.....")
    start_server = websockets.serve(handler, '0.0.0.0', 8765)

    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()


def startWebSocket(queue):
    global dataQueue
    dataQueue = queue
    wst = threading.Thread(target=initSocket)
    wst.daemon = True
    wst.start()
