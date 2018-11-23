import struct

# NOTE only 24bit bmps are supported!


def readAsInt( file, nrBytes, signed ):
    if nrBytes == 2:
        unpackStr = "<H"
    else:
        unpackStr = "<i"
    bytes = file.read(nrBytes)
    val = struct.unpack(unpackStr, bytes)
    return val[0]

def readFile(infile):
    try:
        image_file = open(infile, "rb")

    except IOError:
        print( "Cant load {}".format( infile ) )
        sys.exit(1)

    return readFromStream( image_file )

def readFromStream( image_file ):
    # BMP Header
    type = image_file.read(2)
    bmpSize = readAsInt( image_file, 4, True )
    ignore1 = readAsInt( image_file, 2, True )
    ignore2 = readAsInt( image_file, 2, True )
    bmpDataOffset = readAsInt( image_file, 4, True )

    filePos = 14

    # DIB Header - assume its BITMAPINFOHEADER
    headerSize = readAsInt( image_file, 4, True )
    bmpWidth = readAsInt( image_file, 4, True )
    bmpHeight = readAsInt( image_file, 4, True )

    colorPlanes = readAsInt( image_file, 2, True )   # Must be 1
    bitsPerPixel = readAsInt( image_file, 2, True )  # The color depth of the image. Typical values are 1, 4, 8, 16, 24 and 32.
    compressionType = readAsInt( image_file, 4, True )  
    imageSize = readAsInt( image_file, 4, True )   # Raw bitmap data
    horizontalResolution = readAsInt( image_file, 4, True )
    vertivalResolution = readAsInt( image_file, 4, True )
    nrColorsInPalette = readAsInt( image_file, 4, True ) 
    nrImportantColors = readAsInt( image_file, 4, True ) 

    filePos += 40

    pixelsToRead = bmpHeight * bmpWidth * 3

    # Now skip up to the bitmap data start if we aren't there yet
    offset = bmpDataOffset - filePos
    if offset > 0:
        image_file.read(offset)

    # We need to read pixels in as rows to later swap the order
    # since BMP stores pixels starting at the bottom left.
    rows = []
    durations = []
    row = []
    pixel_index = 0

    pixelsRead = 0
    while True:
        if pixel_index == bmpWidth:
            pixel_index = 0
            rows.insert(0, row)
            durations.append(100)
            if len(row) != bmpWidth * 3:
                raise Exception("Row length is not {}*3 but {}/3.0 = {}".format(bmpWidth, len(row), len(row) / 3.0))
            row = []
        pixel_index += 1

        r_string = image_file.read(1)
        if len(r_string) == 0:
            # This is expected to happen when we've read everything.
            if len(rows) != bmpHeight:
                print( "Warning!!! Read to the end of the file at the correct sub-pixel (red) but we've not read {} rows!".format("bmpHeight"))
            break

        g_string = image_file.read(1)
        b_string = image_file.read(1)
        pixelsRead += 3

        if pixelsRead > imageSize:
            break

        if len(g_string) == 0:
            print( "Warning!!! Got 0 length string for green. Breaking." )
            break

        if len(b_string) == 0:
            print( "Warning!!! Got 0 length string for blue. Breaking." )
            break

        # Pixel format is BGR order in bmp data
        b = ord(r_string)
        g = ord(g_string)
        r = ord(b_string)

        row.append(r)
        row.append(g)
        row.append(b)

    image_file.close()

    return (durations, rows)
