from PIL import Image
from math import floor

class PxlMapGenerator:

    def __init__(self, filename, bit_depth=3):
        self.image_folder = "images"
        self.bit_depth = bit_depth
        self.filename = filename
        self.filepath = self.image_folder + "\\" + self.filename
        self.divisor = (256 / (2 ** self.bit_depth))
        self.orig_colour_map = []  # array of array of 3 long tuples containing the 256b RGB values of the pixels
        self.encoded_colour_map = []
        self.binary_lines = []
        self.hex_lines = []

        # read in pixel data from the selected image into list[list[(tuple,3)]] colourmap
        with Image.open(self.filepath) as im:
            pxl_map = im.load()
            self.image_size = im.size
            for line in range(0, self.image_size[1]):
                self.orig_colour_map.append([pxl_map[pxl, line] for pxl in range(0, self.image_size[0])])

    def encode_pxl_map(self):
        # Encode the RGB pixel colour values using the bit width specified i.e. 3 bits, RGB of 255 = 'd7 or 'b111
        for line in self.orig_colour_map:
            self.encoded_colour_map.append(list(tuple((floor(pxl[0]/self.divisor),
                                                       floor(pxl[1]/self.divisor),
                                                       floor(pxl[2]/self.divisor))) for pxl in self.orig_colour_map[self.orig_colour_map.index(line)]))

    def create_bit_string(self):
        '''output binary string will be structured such that for a bitdepth of 3 bit 2:0 = pixel(0,0)-red,
                                                                                     5:3 = pixel(0,0)-green,
                                                                                     8:6 = pixel(0,0)-blue,
                                                                                     11:9 = pixel(0,1)-red etc...'''
        for line in self.encoded_colour_map:
            tmp_line_str = ''
            for pxl in line:
                tmp_pxl_str = ''
                for pxl_colr in range(0, 3):
                    tmp_bin_str = bin(pxl[pxl_colr])[2:]
                    if len(tmp_bin_str) == 1:
                        tmp_bin_str = '00' + tmp_bin_str
                    elif len(tmp_bin_str) == 2:
                        tmp_bin_str = '0' + tmp_bin_str
                    tmp_pxl_str = tmp_bin_str + tmp_pxl_str # reverse order so it can be read in
                tmp_line_str = tmp_pxl_str + tmp_line_str
            self.binary_lines.append(str(tmp_line_str))

    def hexify_lines(self):
        for bin_line in self.binary_lines:
            tmp_bin_line = bin_line
            tmp_hex_line = ''
            while len(tmp_bin_line) > 4:
                tmp_hex_nibble = hex(int(tmp_bin_line[-4:], 2))[2:]
                tmp_hex_line = tmp_hex_nibble + tmp_hex_line
                tmp_bin_line = tmp_bin_line[:-4]
            tmp_hex_line = hex(int(tmp_bin_line, 2))[2:] + tmp_hex_line
            self.hex_lines.append(str(tmp_hex_line))

    def write_out_COE_file(self):
        self.encode_pxl_map()
        self.create_bit_string()
        self.hexify_lines()
        with open("COE_init.txt", "wt") as file:
            file.write(', '.join(self.hex_lines))

    def create_encoded_image(self):
        self.write_out_COE_file()
        with Image.new('RGB',(self.image_size[0],self.image_size[1])) as im:
            for line in range(0, self.image_size[1]):
                for pxl in range(0, self.image_size[0]):
                    im.putpixel((pxl, line),(int(self.encoded_colour_map[line][pxl][0]*self.divisor),
                                             int(self.encoded_colour_map[line][pxl][1]*self.divisor),
                                             int(self.encoded_colour_map[line][pxl][2]*self.divisor)))
            im.save(self.image_folder + "\\encoded_" + self.filename)

if __name__ == "__main__":
    a = PxlMapGenerator("scouse_slip.png", bit_depth=3)
    a.create_encoded_image()
