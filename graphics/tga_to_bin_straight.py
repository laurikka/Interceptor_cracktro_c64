import sys                                      # enable reading of command line filename

bitlist = list()                                # holds ones and zeroes
bytelist = list()                               # holds ones and zeroes converted to bytes
row = list()
imageslice = list()                             # store vertical slice of the image
imagearray = list()                             # store all the slices of the image
character = list()
font = list()
temp = 0

## read image and convert it to ones and zeroes ###################################################

f = open(sys.argv[1], 'rb')                     # read file specified as first argument

header = f.read(18)                             # get tga-header
sizex = header[12] + (header[13]*256)           # extraxt x-res of image
sizey = header[14] + (header[15]*256)           # extraxt y-res of image

f.seek(18)                                      # skip tga-header

with f:
    while (byte := f.read(1)):                  # walrus operator to read all bytes from file
        if (temp%3==0):                         # read values only from red channel of tga
            if int.from_bytes(byte, "big")  > 1:
                bitlist.append(1)               # if value is above zero, append one
            else:
                bitlist.append(0)               # else append zero
        temp+=1                                 # increase every loop for modulo check

f.close()                                       # close input file

#print(bitlist)

## convert bits to bytes ##########################################################################

for i in range(int(sizex*sizey/8)):
    bytelist.append((128*bitlist[i*8])+(64*bitlist[(i*8)+1])+(32*bitlist[(i*8)+2])+(16*bitlist[(i*8)+3])+(8*bitlist[(i*8)+4])+(4*bitlist[(i*8)+5])+(2*bitlist[(i*8)+6])+(bitlist[(i*8)+7]))

print("bytelist length ",len(bytelist))
print(bytelist)

newFile = open(sys.argv[2], "wb")
for i in range(len(bytelist)):
    newFile.write(bytelist[i].to_bytes(1, byteorder='big'))

newFile.close()
