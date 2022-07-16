import math

HEIGHT = 480
WIDTH  = 640
COLOUR_DEPTH = 1
PIXEL_WIDTH = 3 * COLOUR_DEPTH
PIXELS_PER_LINE = 8
MEMORY_WIDTH = PIXELS_PER_LINE * PIXEL_WIDTH
MEMORY_DEPTH = math.ceil((HEIGHT * WIDTH) / PIXELS_PER_LINE)


def write_mem():
    with open("mem_file.mem", 'w') as file:
        file.write("@000\n")
        for line in range(0, MEMORY_DEPTH):
            tmp_binary = bin(line)[2:]
            tmp_binary = (MEMORY_WIDTH - len(tmp_binary)) * '0' + tmp_binary
            print(tmp_binary)
            file.write(tmp_binary + "\n")

if __name__ == '__main__':
    write_mem()
