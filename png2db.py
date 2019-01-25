#!/usr/local/bin/python
#!/usr/bin/env python
import png
import sys
import os
from subprocess import call, Popen, PIPE
from math import *
from operator import itemgetter
from utils import *
from base64 import b64encode
import array

def readPNG(filename):
    reader = None
    pix = None
    w, h = -1, -1
    try:
        if reader == None:        
            reader=png.Reader(filename)
        img = reader.read()
        pix = list(img[2])
    except:
        print('Could not open image, file exists?')
        return None
    w, h = len(pix[0]), len(pix)
    print ('Opened image %s %dx%d' % (filename, w, h))            
    return pix

foreground=sys.argv[1]
(origname, ext) = os.path.splitext(foreground)
assembly = origname + '.inc'
pic = readPNG(foreground)

columnous=False
xbytes = len(pic[0])//8
nlines = len(pic)
if columnous:
    # the picture is lines of 1 byte per pixel data
    # we need columns of 1 bit per pixel data
    for x in range(xbytes):
        column = ''
        for y in range(0,nlines,2):
            col8=0xff & ~(int(''.join([str(x//255) for x in pic[y][x*8:x*8+8]]),2))
            column += '$%02x,' % col8
        print('db %s' % column[:-1])
else:
    # store the picture as lines
    for y in range(0,nlines,2):
        column = ''
        for x in range(xbytes):
            col8=0xff & ~~(int(''.join([str(x//255) for x in pic[y][x*8:x*8+8]]),2))
            column += '$%02x,' % col8
        print('db %s' % column[:-1])

