import os
import zipfile
import bmpreader
import gifreader

class Theme:

    def __init__(self, infile = None):
        self.imageData = []
        self.frameDurations = []
        self.currentFrame = 0
        self.numberOfFrames = 0
        self.isValid = False
        self.error = None

        rc = False
        if infile == None:
            self.imageData = [[0]*16*3 for _ in range(16)]
            self.frameDurations = [1]
            self.currentFrame = 0

            self.isValid = True
        elif infile.endswith( ".gif"):
            self.isValid = self.read_gif_file( infile )
        elif infile.endswith( ".bmp"):
            self.isValid = self.read_gif_file( infile )
            #self.isValid = self.read_bitmap_file( infile )
        elif infile.endswith( ".zip"):
            self.isValid = self.read_zip_file( infile )
        else:
            self.error =  "Unsupported file type"

        self.numberOfFrames = len(self.frameDurations)

    def getFrame(self):
        rows = self.imageData[self.currentFrame*16:(self.currentFrame+1)*16]
        delayTime = self.frameDurations[self.currentFrame]
        return (rows, delayTime)

    def nextFrame(self):
        (rows, delayTime) = self.getFrame()

        self.currentFrame += 1
        if self.currentFrame >= self.numberOfFrames:
            self.currentFrame = 0
        return (rows, delayTime)

    def read_bitmap_file(self, infile):
        (frameDurations, rows) = bmpreader.readFile(infile)
        self.imageData = rows
        self.frameDurations = frameDurations
        return True

    def read_gif_file(self, infile):
        (frameDurations, rows) = gifreader.readFile(infile)
        self.imageData = rows
        self.frameDurations = frameDurations
        return True

    def read_zip_file(self, infile):
        zfile = zipfile.ZipFile(infile)
        fileList = zfile.infolist()

        fileList = [x for x in fileList if any(c.isdigit() or c.endswith( "bmp" ) for c in x.filename)]
        fileList.sort(key=lambda f: int(os.path.splitext(f.filename)[0]))

        self.imageData = []
        for finfo in fileList:
            
            ifile = zfile.open(finfo)
            (frameDurations, data) = bmpreader.readFromStream( ifile )
            self.imageData.extend(data)
            self.frameDurations.append(100)

        return True

    def setFramePixel( self, x, y, r, g, b ):
        (rows, delayTime) = self.getFrame()
        xpos1 = (x*3)
        xpos2 = (x*3)+1
        xpos3 = (x*3)+2
        rows[y][xpos1] = r
        rows[y][xpos2] = g
        rows[y][xpos3] = b

if __name__ == '__main__':
    Theme()
    #rows = read_zip_file( "./brucelee.zip")
    #print( "read {} rows in total".format(len(rows)))