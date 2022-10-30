from PIL import Image


class VGAImage:

    def __init__(self, image_name, height=480, width=640, crop=False, crop_x=0, crop_y=0):

        self.height = height
        self.width = width
        self.tile_size = 1
        if crop:
            self.image = Image.open(image_name).crop((crop_x, crop_y, crop_x + width, crop_y + height))
        else:
            self.image = Image.open(image_name).resize((self.width, self.height))
        self.comp_image = Image.new("RGBA", (width, height), 0)
        self.tmp_image = Image.new("RGBA", (width, height), 0)
        self.tiled_image = Image.new("RGBA", (width, height), 0)
        self.orig_pxl_arr = []
        self.mem_pxl_arr = []

    # create compressed version of image (use 4b RGB to match required VGA output). Note that the result is still 8b RGB
    # encoded, but the colour values are multiples of 16, therefore enabling them to be used with 4b colour encoding.
    def create_comp_image(self):
        for y in range(0, self.height):
            # iterate through lines
            tmp_orig_pxl_arr = []
            for x in range(0, self.width):
                # iterate through pixels
                tmp_pxl = self.image.getpixel((x, y))  # take pixel
                # try to normalise the RGB pixel values
                tmp_comp_pxl = ((tmp_pxl[0] >> 4) << 4,
                                (tmp_pxl[1] >> 4) << 4,
                                (tmp_pxl[2] >> 4) << 4, 255)
                tmp_orig_pxl_arr.append(tmp_pxl)
                # create an image using the compressed pixel values
                self.comp_image.putpixel((x, y), tmp_comp_pxl)
            self.orig_pxl_arr.append(tmp_orig_pxl_arr)

    # create a greyscale version of the image using the compressed image as the original and store in tmp_image
    def create_grey_image(self):
        for y in range(0, self.height):
            # iterate through lines
            for x in range(0, self.width):
                # shifting by 4 and then multiplying by 16 to encode into 4b colours
                mp_pxl_val = (int((self.comp_image.getpixel((x, y))[0] * 0.021) +
                                  (self.comp_image.getpixel((x, y))[1] * 0.72) +
                                  (self.comp_image.getpixel((x, y))[2] * 0.07)) >> 4) * 16
                self.tmp_image.putpixel((x, y), (mp_pxl_val, mp_pxl_val, mp_pxl_val, 255))

    # create a green version of the image using the compressed image as the original and store in tmp_image
    # Note that this creates a greyscale image first and uses the result to create a green tint version of the image
    def create_green_image(self):
        self.create_grey_image()
        for y in range(0, self.height):
            # iterate through lines
            for x in range(0, self.width):
                self.tmp_image.putpixel((x, y), (0, self.tmp_image.getpixel((x, y))[1], 0, 255))

    # Uses coordinates to return the mean average colour value for a tile of tile_size x tile_size dimensions
    def average_tile(self, starting_x, starting_y, tile_size):
        tile = [0, 0, 0]
        for y in range(starting_y, starting_y + tile_size):
            for x in range(starting_x, starting_x + tile_size):
                for rgb in range(0, 3):
                    tile[rgb] += self.tmp_image.getpixel((x, y))[rgb]

        for rgb in range(0, 3):
            # shifting by 4 and then multiplying by 16 to encode into 4b colours
            tile[rgb] = (int(tile[rgb]/(tile_size*tile_size)) >> 4) * 16
        return tile

    # Creates a certain tmp_image depending on the colour_option and then averages the pixels into tiles of
    # tile_size x tile_size dimensions.
    # Additionally, this should populate the mem_pxl_arr attribute with 1D array of scaled RGB values
    def create_tiled_image(self, tile_size, colour_option="colour"):

        self.tile_size = tile_size
        # compress image
        self.create_comp_image()
        # generate appropriate tmp_image
        if colour_option == "colour":
            self.tmp_image = self.comp_image
        elif colour_option == "green":
            self.create_green_image()
        elif colour_option == "grey":
            self.create_grey_image()
        # iterate through the pixels and replace each with an average value of the block
        for y in range(0, self.height, self.tile_size):
            for x in range(0, self.width, self.tile_size):
                tile_val = self.average_tile(x, y, self.tile_size)
                if (x % self.tile_size == 0) and (y % self.tile_size) == 0:
                    # populate RGB memory array
                    self.mem_pxl_arr.append([tile_val[0] >> 4, tile_val[1] >> 4, tile_val[2] >> 4])
                for tile_y in range(y, y + self.tile_size):
                    for tile_x in range(x, x + self.tile_size):
                        self.tiled_image.putpixel((tile_x, tile_y), (tile_val[0], tile_val[1], tile_val[2], 255))

    def show_tiled_image(self):
        self.tiled_image.show()

    def show_comp_image(self):
        self.comp_image.show()

    def show_tmp_image(self):
        self.tmp_image.show()

    def show_image(self):
        self.image.show()

    def get_mem_pxl_array(self):
        return self.mem_pxl_arr


class MemArray:
    # When initialised, class should create a VGA_Image and then use it to generate an array which should represent the
    # frame buffer memory contents
    def __init__(self, tiles_per_mem_row, image_name, tile_size_pxl=4, colour_option="colour", height=480, width=640,
                 crop=False, crop_x=0, crop_y=0):

        self.vga_image = VGAImage(image_name, height, width, crop, crop_x, crop_y)
        self.vga_image.create_tiled_image(tile_size_pxl, colour_option)

        self.memory_arr = []
        line = ""
        pxl_cnt_max = int((self.vga_image.width * self.vga_image.height) / (self.vga_image.tile_size ** 2))
        current_pxl_cnt = 0

        # iterate through the pixels in the RGB memory array and transform them to binary and split the 1D array into
        # rows according to the specified row width
        while current_pxl_cnt < pxl_cnt_max:
            for pxl_id in range(0, tiles_per_mem_row):
                curr_pxl = self.vga_image.mem_pxl_arr[(current_pxl_cnt + pxl_id)]
                line = f'{curr_pxl[2]:04b}' + line  # B
                line = f'{curr_pxl[1]:04b}' + line  # G
                line = f'{curr_pxl[0]:04b}' + line  # R
            current_pxl_cnt += tiles_per_mem_row
            self.memory_arr.append(line)
            line = ""

    def get_mem_arr(self):
        return self.memory_arr


if __name__ == "__main__":

    test_mem_arr = MemArray(8, "/home/tom/Pictures/pulla.jpg", colour_option="green")
    test_mem_arr.vga_image.show_tiled_image()

    print(test_mem_arr.vga_image.get_mem_pxl_array()[24:48])
    print(test_mem_arr.get_mem_arr()[4:6])
    for i in range(96, 192, 4):
        print(test_mem_arr.vga_image.tiled_image.getpixel((i, 0)))


