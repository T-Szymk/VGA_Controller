/* Code to contain implementation of socket client functions used by VGA 
   simulator */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>

#include <sys/socket.h>

#include <netinet/in.h>
#include <arpa/inet.h>

#include "../includes/dpiheader.h"

#define PORT    (uint16_t)(32023)
#define ADDRESS "127.0.0.1"
#define BUFF_SIZE 2048

typedef struct sockaddr SA;

static struct sockaddr_in addr = {0};
static int client_fd, status = -1;
static char buff[BUFF_SIZE] = {0};


void init_addr(void) {
  addr.sin_family = AF_INET;
  addr.sin_port = htons(PORT);
  addr.sin_addr.s_addr = inet_addr(ADDRESS);
}

int client_connect(void) {

  init_addr();

  // create socket
  if ((client_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
    printf("Socket Creation Error!");
    return EXIT_FAILURE;
  };

  // attempt to connect
  if ((status = connect(client_fd, (SA*)(&addr), sizeof(addr))) < 0) {
    printf("Connection Error!");
    close(client_fd);
    return EXIT_FAILURE;
  }

  printf("Successfully connected to server @ %s:%d\n", ADDRESS, PORT);
  
  return EXIT_SUCCESS;
}

int client_close(void) {
  printf("Closing socket and exiting program.\n");
  close(client_fd);
  return EXIT_SUCCESS;
}

int client_send_reset(void) {
  memset(buff, 0, BUFF_SIZE); // clear data in buffer
  char* tmp_buff = "RESET";
  memcpy(buff, tmp_buff, 5);
  
  if ((status = send(client_fd, buff, BUFF_SIZE, 0)) < 0) {
    perror("Send Error! ");
    close(client_fd);
    return EXIT_FAILURE;
  } else {
    printf("Client sent %d bytes...\n", status);
  }

   memset(buff, 0, BUFF_SIZE);

   return EXIT_SUCCESS;
}

int client_send_data(void) {

  if ((status = send(client_fd, buff, BUFF_SIZE, 0)) < 0) {
      perror("Send Error! ");
      close(client_fd);
      return EXIT_FAILURE;
    } else {
      printf("Client sent %d bytes...\n", status);
    }

  // clear buff
  memset(buff, 0, BUFF_SIZE);

  return EXIT_SUCCESS;
}

int add_pxl_to_client_buff_mono(const int r, const int g, const int b, const int pos) {
  // Assign values to 3 bytes and copy 3 bytes into the buff
  uint32_t tmp = (r) ? 255 : 0;
  tmp |= (g) ? (255 << 8) : 0;
  tmp |= (b) ? (255 << 16) : 0;

  memcpy((buff + (3 * pos)), &tmp, 3);

  return EXIT_SUCCESS;
}

int add_pxl_to_client_buff(const int r, const int g, const int b, const int pos) {
  // Assign values to 3 bytes and copy 3 bytes into the buff
  // Each 4b value x16 ( << 4) to scale to 8b encoding scheme
  uint32_t tmp = 0;
  tmp |= r << ( 0 + 4);
  tmp |= g << ( 8 + 4);
  tmp |= b << (16 + 4);

  memcpy((buff + (3 * pos)), &tmp, 3);

  return EXIT_SUCCESS;
}