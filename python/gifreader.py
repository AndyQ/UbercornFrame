from PIL import Image
import sys
import itertools

try:
    xrange
except NameError:
    xrange = range

def readFile(infile):
    try:
        im = Image.open(infile)

        is_gif = False
        if infile.endswith("gif"):
            is_gif = True
        print( im.info )
    except IOError:
        print( "Cant load {}".format( infile ) )
        sys.exit(1)
    i = 0
    mypalette = im.getpalette()

    rows = []
    durations = []
    frame = 0
    try:
        while 1:
            frame += 1
            if "duration" in im.info:
                duration = im.info["duration"]
            else:
                duration = 100
            durations.append(duration)

            #print( "Frame {} - {}".format(frame, duration) )

            if is_gif == True:
                im.putpalette(mypalette)
            new_im = Image.new("RGB", im.size)

            new_im.paste(im)
            if is_gif == True:
                new_im.thumbnail((16,16), Image.BICUBIC)

            pixels = list(new_im.getdata())
            pixels = list(itertools.chain(*pixels))
            width, height = new_im.size
            pixels = [pixels[j * (width*3):(j + 1) * (width*3)] for j in xrange(height)]
            rows.extend( pixels )

            #new_im.save('test%d.png' % i)

            i += 1
            mypalette = im.getpalette()
            im.seek(im.tell() + 1)

    except EOFError:
        pass # end of sequence

    return (durations,rows)

if __name__ == '__main__':
    processImage( "bruce_lee.gif")