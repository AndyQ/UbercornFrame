import asyncio
import websockets
import threading
from time import sleep
from queue import Queue
from webserver import initWebServer

dataQueue = None
apiKey = None

async def handler(websocket, path):
    global dataQueue
    hasValidAuth = False
    try:
        while True:
            message = await websocket.recv()

            if hasValidAuth == False:
                if message.startswith( "CONNECT" ):
                    tokens = message.split( " " )
                    print( "Looking for {} and found {}".format( apiKey, message))
                    print( "Looking for {} and found {}".format( apiKey, message))
                    if len(tokens) == 2 and tokens[1] == apiKey:
                        hasValidAuth = True
                        dataQueue.put( "CONNECT" )
                        await websocket.send("OK")
                    else:
                        print( "Invalid API KEY")
                        await websocket.send("INVALID/MISSING API KEY")
                        break
            else:
                dataQueue.put( message )
                await websocket.send("OK")
    except Exception as e:
        print( "Socket closed - {}!".format(e) )
        dataQueue.put( "DISCONNECT" )

def initSocket():
    asyncio.set_event_loop(asyncio.new_event_loop())

    print( "STARTING SOCKET.....")
    start_server = websockets.serve(handler, '0.0.0.0', 8765)

    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()


def startWebSocket(queue, apiKeyValue):
    global dataQueue, apiKey

    apiKey = apiKeyValue

    if apiKey == None:
        print( "Websocket Server not starting as no API Key as been generated.")
        print( "Use player.py --generate to generate a new api key")
        print( "Use player.py --showAPI to show the QRCode for the API Key" )
        return

    dataQueue = queue
    wst = threading.Thread(target=initSocket)
    wst.daemon = True
    wst.start()
