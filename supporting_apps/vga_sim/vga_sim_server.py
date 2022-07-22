# socket TCP server
import socket
import pygame

DEBUG = False

# socket constants
HOST = "127.0.0.1"
PORT = 32023
BUFF_SIZE = 2048
FRAME_LIMIT = 255


class vga_sim_window():

    def __init__(self, width, height):
        self.background_colour = (0, 0, 0)
        self.height = height
        self.width = width
        # initialise pygame module
        pygame.init()
        self.font = pygame.font.SysFont(None, 60)
        self.no_connection_msg = self.font.render("No Connection", True, (255, 255, 255))
        self.end_sim_msg = self.font.render("Close Window", True, (255, 255, 255))
        # initialise screen object
        self.screen = pygame.display.set_mode((width, height))
        # Set the caption of the screen
        pygame.display.set_caption('VGA Simulator')
        # Fill the background colour to the screen
        self.screen.fill(self.background_colour)

    def update_display(self):
        pygame.display.update()

    def blank_screen(self):
        self.screen.fill(self.background_colour)
        self.update_display()

    def display_no_connection(self):
        self.screen.fill(self.background_colour)
        self.screen.blit(self.no_connection_msg, ((self.width / 2) - 150, (self.height / 2) - 30))
        self.update_display()

    def display_close_window(self):
        self.screen.fill(self.background_colour)
        self.screen.blit(self.end_sim_msg, ((self.width / 2) - 150, (self.height / 2) - 30))
        self.update_display()

    def set_pxl(self, x, y, color):
        self.screen.set_at((x, y), color)


# Read pixel out of the buffer and assign pixel value to the screen
def process_data(data, line, vga_sim_obj):
    line_arr = []
    for pxl_id in range(0, vga_sim_obj.width):
        tmp_pxl = int.from_bytes(data[(3 * pxl_id):(3 * pxl_id) + 3], "little")
        b = tmp_pxl & 255
        g = (tmp_pxl >> 8) & 255
        r = (tmp_pxl >> 16) & 255
        vga_sim_obj.set_pxl(pxl_id, line, (r, g, b))
    vga_sim_obj.update_display()


def main():
    vga_sim = vga_sim_window(640, 480)

    running = True

    vga_sim.display_no_connection()

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:

        sock.bind((HOST, PORT))
        sock.listen()
        conn, addr = sock.accept()

        with conn:

            vga_sim.blank_screen()

            # Variable to keep our game loop running
            print(f"Connected to from {addr}")
            line_id = 0

            while True:

                data = conn.recv(BUFF_SIZE)

                if data != b'':

                    if DEBUG:
                        print(f"Received: {data}")

                    if data[0:5] == b'RESET': # if reset string received, clear screen and return to top

                        line_id = 0
                        vga_sim.blank_screen()

                    else:
                        process_data(data, line_id, vga_sim)

                        if line_id == (vga_sim.height - 1):
                            line_id = 0
                        else:
                            line_id = line_id + 1
                else:
                    break
        # Once socket it closed, sit in loop and alert User that the screen must
        # be closed
        print("Left socket Loop. Close Simulation Window.")
        while running:
            vga_sim.display_close_window()
            for event in pygame.event.get():
                # Check for QUIT event
                if event.type == pygame.QUIT:
                    running = False


if __name__ == "__main__":
    main()


