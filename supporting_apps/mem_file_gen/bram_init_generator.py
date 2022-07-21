import math
import vga_image as vga

HEIGHT = 480
WIDTH  = 640
COLOUR_DEPTH = 1
PIXEL_WIDTH = 3 * COLOUR_DEPTH
PIXELS_PER_LINE = 8
MEMORY_WIDTH = PIXELS_PER_LINE * PIXEL_WIDTH
MEMORY_DEPTH = math.ceil((HEIGHT * WIDTH) / PIXELS_PER_LINE)

IMAGE_NAME = "floral"
IMAGE_EXT = ".jpg"
IMAGE_PATH = f"/home/tom/Pictures/{IMAGE_NAME}{IMAGE_EXT}"
print(IMAGE_PATH)
OUTPUT_FILENAME = IMAGE_NAME


def write_incrementing_value_mem(depth):
    with open("mem_file.mem", 'w') as file:
        file.write("@000\n")
        for line in range(0, depth):
            tmp_binary = bin(line)[2:]
            tmp_binary = (MEMORY_WIDTH - len(tmp_binary)) * '0' + tmp_binary
            print(tmp_binary)
            file.write(tmp_binary + "\n")


def write_arr2mem(mem_arr, depth, output_filename):
    with open(output_filename + ".mem", 'w') as file:
        file.write("@000\n")
        for line in range(0, depth):
            tmp_binary = bin(line)[2:]
            file.write(mem_arr[line] + "\n")


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    image = vga.VGAImage(HEIGHT, WIDTH, IMAGE_PATH, False, 0, 0)
    image.show_image()
    image.show_comp_image()
    mem_arr = vga.MemArray(PIXELS_PER_LINE, image.width, image.height, image.get_mem_pxl_array())
    write_arr2mem(mem_arr.get_mem_arr(), MEMORY_DEPTH, OUTPUT_FILENAME)

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
