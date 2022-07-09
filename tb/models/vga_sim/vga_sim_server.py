# socket TCP server
import socket
import pygame

# socket constants
HOST = "127.0.0.1"
PORT = 32023
BUFF_SIZE = 2048
FRAME_LIMIT = 255

# Define the background colour
# using RGB color coding.
background_colour = (0, 0, 0)
# Define the dimensions of
# screen object(width,height)
width  = 640
height = 480
screen = pygame.display.set_mode((width, height))
# Set the caption of the screen
pygame.display.set_caption('VGA_test')
# Fill the background colour to the screen
screen.fill(background_colour)
# Update the display using flip
pygame.display.flip()


def process_data(data, line):
    line_arr = []
    for pxl_id in range(0, width):
        tmp_pxl = int.from_bytes(data[(3*pxl_id):(3*pxl_id)+3], "little")
        r = tmp_pxl & 255
        g = (tmp_pxl >> 8) & 255
        b = (tmp_pxl >> 16) & 255
        screen.set_at((pxl_id, line), (r, g, b))


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind((HOST, PORT))
        sock.listen()
        conn, addr = sock.accept()
        with conn:
            # Variable to keep our game loop running
            print(f"Connected to from {addr}")
            line_id = 0
            while 1:
                data = conn.recv(BUFF_SIZE)
                if data != b'':

                    print(f"Received: {data}")

                    process_data(data, line_id)
                    if line_id == (height - 1):
                        line_id = 0
                        break
                    else:
                        line_id = line_id + 1
                    pygame.display.update()

    print("Left socket Loop.")
    while 1:
        for event in pygame.event.get():
            # Check for QUIT event
            if event.type == pygame.QUIT:
                break


if __name__ == "__main__":
    main()


