import math
import vga_image as vga

# TODO: input and output filenames should be arguments

HEIGHT = 480
WIDTH = 640
COLOUR_DEPTH = 4
PIXEL_WIDTH = 3 * COLOUR_DEPTH
TILES_PER_MEM_ROW = 4  # defines how many tiles are contained within each row of BRAM
TILE_SIZE = 2
MEMORY_WIDTH = TILES_PER_MEM_ROW * PIXEL_WIDTH
MEMORY_DEPTH = math.ceil((HEIGHT * WIDTH) / (TILES_PER_MEM_ROW * (TILE_SIZE ** 2)))

IMAGE_NAME = "scouse_slip"
IMAGE_EXT = ".png"
IMAGE_PATH = f"../images/{IMAGE_NAME}{IMAGE_EXT}"
OUTPUT_FILENAME = IMAGE_NAME


# function that will write out a test memory initialisation file which contains incrementing values within each pixel
# to be used in testing
def write_incrementing_value_mem(depth):
    with open("mem_file.mem", 'w') as file:
        file.write("@000\n")
        for line in range(0, depth):
            tmp_binary = bin(line)[2:]
            tmp_binary = (MEMORY_WIDTH - len(tmp_binary)) * '0' + tmp_binary
            print(tmp_binary)
            file.write(tmp_binary + "\n")


# take memory array and write it out into a memory init file which can subsequently be read using readmemb()
def write_arr2mem(mem_array, output_filename):
    with open(output_filename + ".mem", 'w') as file:
        file.write(f"// Input Image  : {IMAGE_PATH}\n")
        file.write(f"// Output File  : {OUTPUT_FILENAME}.mem\n")
        file.write(f"// Memory Depth : {len(memory_array.get_mem_arr())} rows\n")
        file.write(f"// Memory Width : {len(memory_array.get_mem_arr()[0])} bits\n")
        file.write(f"// Tile Size    : {TILE_SIZE} pixels\n")
        file.write("@000\n")
        for line in range(0, len(mem_array)):
            tmp_binary = bin(line)[2:]
            file.write(mem_array[line] + "\n")


if __name__ == '__main__':

    memory_array = vga.MemArray(TILES_PER_MEM_ROW, IMAGE_PATH, TILE_SIZE, colour_option="colour")
    memory_array.vga_image.show_tiled_image()
    write_arr2mem(memory_array.get_mem_arr(), OUTPUT_FILENAME)
    print("------------------------------------------------")
    print(f"Input Image  : {IMAGE_PATH}")
    print(f"Output File  : {OUTPUT_FILENAME}.mem")
    print(f"Memory Depth : {len(memory_array.get_mem_arr())} rows")
    print(f"Memory Width : {len(memory_array.get_mem_arr()[0])} bits")
    print(f"Tile Size    : {TILE_SIZE} pixels")
    print("------------------------------------------------")

