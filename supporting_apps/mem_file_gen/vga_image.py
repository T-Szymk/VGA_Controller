from PIL import Image


class VGAImage:

    def __init__(self, height, width, image_name):

        # used to affect the scaling threshold used for compression
        white_factor = 1

        self.height = height
        self.width = width
        self.image = Image.open(image_name).resize((self.width, self.height))
        self.comp_image = Image.new("RGBA", (640, 480), 0)
        self.orig_pxl_arr = []
        self.mem_pxl_arr = []

        for y in range(0, self.height):
            # iterate through lines
            tmp_orig_pxl_arr = []
            for x in range(0, self.width):
                # iterate through pixels
                tmp_pxl = self.image.getpixel((x, y))  # take pixel
                # try to normalise the RGB pixel values
                tmp_mem_pxl = (round(tmp_pxl[0]/(255 * white_factor)),
                               round(tmp_pxl[1]/(255 * white_factor)),
                               round(tmp_pxl[2]/(255 * white_factor)))
                tmp_comp_pxl = (round(tmp_pxl[0]/(255 * white_factor)) * 255,
                                round(tmp_pxl[1]/(255 * white_factor)) * 255,
                                round(tmp_pxl[2]/(255 * white_factor)) * 255, 255)
                tmp_orig_pxl_arr.append(tmp_pxl)
                self.mem_pxl_arr.append(tmp_mem_pxl)
                # create an image using the compressed pixel values
                self.comp_image.putpixel((x, y), tmp_comp_pxl)
            self.orig_pxl_arr.append(tmp_orig_pxl_arr)

    def show_comp_image(self):
        self.comp_image.show()

    def show_image(self):
        self.image.show()

    def get_mem_pxl_array(self):
        return self.mem_pxl_arr


class MemArray:

    def __init__(self, pxl_per_line, width, height, mem_pxl_arr):
        self.memory_arr = []
        line = ""
        pxl_cnt_max = (width * height)
        current_pxl_cnt = 0
        while current_pxl_cnt < pxl_cnt_max:
            for pxl_id in range(0, pxl_per_line):
                curr_pxl = mem_pxl_arr[(current_pxl_cnt + pxl_id)]
                line = str(curr_pxl[2]) + line  # B
                line = str(curr_pxl[1]) + line  # G
                line = str(curr_pxl[0]) + line  # R
            current_pxl_cnt += pxl_per_line
            self.memory_arr.append(line)
            line = ""

    def get_mem_arr(self):
        return self.memory_arr


if __name__ == "__main__":

    test_image = VGAImage(480, 640, "/home/tom/Pictures/james_webb_first.png")
    test_mem_arr = MemArray(8, test_image.width, test_image.height, test_image.get_mem_pxl_array())

    test_image.show_image()
    test_image.show_comp_image()
    print(test_image.get_mem_pxl_array()[8:16])
    print(test_mem_arr.get_mem_arr()[1:2])


