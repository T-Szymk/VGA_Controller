from PIL import Image, ImageColor
from math import floor

class PxlMapGenerator:

    def __init__(self, filename, bit_depth=3):
        self.bit_depth = bit_depth
        self.memory_file_init = []
        self.pxl_map = []
        self.orig_colour_map = []
        self.filepath = "images\\" + filename
        # read in pixel data from the selected image into list[list[(tuple,3)]] colourmap
        with Image.open(self.filepath) as im:
            line_pxls = []
            pxl_map = im.load()
            self.image_size = im.size
            for line in range(0, self.image_size[1]):
                line_pxls.clear()
                for pxl in range(0, self.image_size[0]):
                    line_pxls.append(pxl_map[pxl,line])
                self.orig_colour_map.append(line_pxls.copy())

    def create_pxl_map(self):
        output_map = []
        divisor = (256 / (2**self.bit_depth))
        for line in self.orig_colour_map:
            output_map.clear()
            for pxl in self.orig_colour_map[self.orig_colour_map.index(line)]:
                scaled_colr_vals = [0, 0, 0]
                for idx in range(0, len(scaled_colr_vals)):
                   scaled_colr_vals[idx] = floor(pxl[idx]/divisor)
                output_map.append(bin(scaled_colr_vals[0] | (scaled_colr_vals[1] << self.bit_depth) | (scaled_colr_vals[2] << (self.bit_depth*2)))[2:]) # concat colour vals into a single value
            self.pxl_map.append(output_map.copy())

if __name__ == "__main__":
    a = PxlMapGenerator("star.png", 3)
    a.create_pxl_map()

