#!/usr/bin/env python
import argparse
import colorsys
import math
import time
from queue import Queue

import comms
import webserver
from theme import Theme

try:
    import unicornhathd
    print("unicorn hat hd detected")
except ImportError:
    from unicorn_hat_sim import unicornhathd

animating = True
isConnected = False
theme = None
queue = None

def handleQueue():
    global theme, queue
    while not queue.empty():
        item = queue.get()
        print( item )

        tokens = item.split(" ")
        cmd = tokens[0]
        if cmd == "CONNECT":
            theme = Theme()
            isConnected = True
        elif cmd.startswith("SET") and len(tokens) == 6:
            x = int(tokens[1])
            y = int(tokens[2])
            r = int(tokens[3])
            g = int(tokens[4])
            b = int(tokens[5])

            theme.setFramePixel( x, y, r, g, b)
        elif cmd == "FRAME":
            # Two items here - cmd and data
            data = queue.get()
            pos = 0
            for x in range(0, 16):
                for y in range(0, 16):
                    r = data[pos]
                    g = data[pos+1]
                    b = data[pos+2]
                    theme.setFramePixel( x, y, r, g, b)

                    pos += 3
        elif cmd.startswith( "STOP" ):
            theme = Theme( None )

        elif cmd.startswith( "PLAY" ):
            # cmd consists of PLAY:filename
            filename = cmd.split(":")[1]
            path = "./images/{}".format(filename)
            theme = Theme( path )

        elif cmd.startswith( "SAVE" ):
            # Two items here - cmd and data
            # cmd consists of SAVE:filename
            data = queue.get()

            filename = cmd.split(":")[1]
            path = "./images/{}".format(filename)

            # Write to file
            with open( path, "wb" ) as outf:
                outf.write(data)


def setPixel( x, y, r, g, b ):
    unicornhathd.set_pixel(abs(x - 15), y, r, g, b)

def updateThemeFrame():
    global theme
    (rows, delayTime) = theme.nextFrame()

    for y in range(0, 16):
        for x in range(0, 16):
            r = rows[y][(x*3)]
            g = rows[y][(x*3)+1]
            b = rows[y][(x*3)+2]

            setPixel( x, y, r, g, b )    

    #print( "frame - {} duration - {}".format( frame, theme.frameDurations[frame]) )
    # Why we have to show twice - no idea
    # Required for unicorn-hat-sim otherwise we seem to be a frame out!
    # not yet tried on real device
    unicornhathd.show()
    unicornhathd.show()

    time.sleep(delayTime/1000.0)

def main( filename ):
    global theme, queue

    queue = Queue()

    comms.startWebSocket(queue)
    webserver.startWebServer(queue)

    theme = Theme( filename )
    if not theme.isValid:
        print( theme.error )
        exit(1)

    try:
        unicornhathd.rotation(0)
        frame = 0
        yPos = 0
        while True:
            handleQueue()

            updateThemeFrame()

    except KeyboardInterrupt:
        unicornhathd.off()

if __name__ == '__main__':

    parser = argparse.ArgumentParser(prog='player.py')

    parser.add_argument('-f', '--file', help='Filename to load')
    args = parser.parse_args()

    main( args.file )
