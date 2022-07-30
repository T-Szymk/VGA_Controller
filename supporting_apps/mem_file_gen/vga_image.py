from PIL import Image


class VGAImage:

    def __init__(self, height, width, image_name, crop=False, crop_x=0, crop_y=0):

        self.height = height
        self.width = width
        self.tile_length = 1
        if crop:
            self.image = Image.open(image_name).crop((crop_x, crop_y, crop_x + width, crop_y + height))
        else:
            self.image = Image.open(image_name).resize((self.width, self.height))
        self.comp_image = Image.new("RGBA", (width, height), 0)
        self.tmp_image = Image.new("RGBA", (width, height), 0)
        self.tiled_image = Image.new("RGBA", (width, height), 0)
        self.orig_pxl_arr = []
        self.mem_pxl_arr = []

    # create 1b RGB version of image
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

    def create_grey_image(self):
        for y in range(0, self.height):
            # iterate through lines
            for x in range(0, self.width):
                # shifting by 4 and then multiplying by 16 to encode into 4b colours
                mp_pxl_val = (int((self.comp_image.getpixel((x, y))[0] * 0.021) +
                                  (self.comp_image.getpixel((x, y))[1] * 0.72) +
                                  (self.comp_image.getpixel((x, y))[2] * 0.07)) >> 4) * 16
                self.tmp_image.putpixel((x, y), (mp_pxl_val, mp_pxl_val, mp_pxl_val, 255))

    def create_green_image(self):
        self.create_grey_image()
        for y in range(0, self.height):
            # iterate through lines
            for x in range(0, self.width):
                self.tmp_image.putpixel((x, y), (0, self.tmp_image.getpixel((x, y))[1], 0, 255))

    def average_tile(self, starting_x, starting_y, tile_length):
        tile = [0, 0, 0]
        for y in range(starting_y, starting_y + tile_length):
            for x in range(starting_x, starting_x + tile_length):
                for rgb in range(0, 3):
                    tile[rgb] += self.tmp_image.getpixel((x, y))[rgb]

        for rgb in range(0, 3):
            # shifting by 4 and then multiplying by 16 to encode into 4b colours
            tile[rgb] = (int(tile[rgb]/(tile_length*tile_length)) >> 4) * 16
        return tile

    def create_tiled_image(self, tile_length, colour_option="colour"):

        self.tile_length = tile_length

        self.create_comp_image()

        if colour_option == "colour":
            self.tmp_image = self.comp_image
        elif colour_option == "green":
            self.create_green_image()
        elif colour_option == "grey":
            self.create_grey_image()

        for y in range(0, self.height, self.tile_length):
            for x in range(0, self.width, self.tile_length):
                tile_val = self.average_tile(x, y, self.tile_length)
                if (x % self.tile_length == 0) and (y % self.tile_length) == 0:
                    self.mem_pxl_arr.append([tile_val[0] >> 4, tile_val[1] >> 4, tile_val[2] >> 4])
                for tile_y in range(y, y + self.tile_length):
                    for tile_x in range(x, x + self.tile_length):
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

    def __init__(self, pxl_per_line, vga_obj):
        self.memory_arr = []
        line = ""
        pxl_cnt_max = int((vga_obj.width * vga_obj.height) / (vga_obj.tile_length ** 2))
        current_pxl_cnt = 0
        print(len(vga_obj.mem_pxl_arr))
        while current_pxl_cnt < pxl_cnt_max:
            for pxl_id in range(0, pxl_per_line):
                curr_pxl = vga_obj.mem_pxl_arr[(current_pxl_cnt + pxl_id)]
                line = f'{curr_pxl[2]:04b}' + line  # B
                line = f'{curr_pxl[1]:04b}' + line  # G
                line = f'{curr_pxl[0]:04b}' + line  # R
            current_pxl_cnt += pxl_per_line
            self.memory_arr.append(line)
            line = ""

    def get_mem_arr(self):
        return self.memory_arr


if __name__ == "__main__":

    test_image = VGAImage(480, 640, "/home/tom/Pictures/pulla.jpg", False, 0, 0)

    test_image.create_tiled_image(4, "green")
    test_image.show_tiled_image()

    test_mem_arr = MemArray(8, test_image)

    print(test_image.get_mem_pxl_array()[8:16])
    print(test_mem_arr.get_mem_arr()[1:2])


