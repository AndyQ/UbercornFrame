#!/usr/bin/env python
import argparse
import colorsys
import math
import time

import comms
from theme import Theme

try:
    import unicornhathd
    print("unicorn hat hd detected")
except ImportError:
    from unicorn_hat_sim import unicornhathd

animating = True
isConnected = False
theme = None

def handleQueue():
    global theme
    while not comms.q.empty():
        item = comms.q.get()
        #print( item )

        tokens = item.split(" ")
        if tokens[0] == "CONNECT":
            theme = Theme()
            isConnected = True
        elif tokens[0].startswith("SET") and len(tokens) == 6:
            x = int(tokens[1])
            y = int(tokens[2])
            r = int(tokens[3])
            g = int(tokens[4])
            b = int(tokens[5])

            theme.setFramePixel( x, y, r, g, b)
        elif tokens[0] == "FRAME":
            # Two items here - cmd and data
            data = comms.q.get()
            pos = 0
            for x in range(0, 16):
                for y in range(0, 16):
                    r = data[pos]
                    g = data[pos+1]
                    b = data[pos+2]
                    theme.setFramePixel( x, y, r, g, b)

                    pos += 3


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
    global theme
    comms.startWebSocket()
    comms.startWebServer()

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