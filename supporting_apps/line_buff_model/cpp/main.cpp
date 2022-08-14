#include <iostream>

#include "SPRAM.h"
#include "skylight_defs.h"

void run_buff_ctrl_model();
void run_buff_model();

int main() {

  SPRAM frame_buffer(PXL_PER_MEM_ROW, FRAME_BUFF_DEPTH);

  frame_buffer.set_memory_zero();

  memory_row_t test_row(PXL_PER_MEM_ROW); // reserve space

  for(int pixel = 0; pixel < PXL_PER_MEM_ROW; pixel++) {
    test_row[pixel] = {42, 69, 200};
  }

  frame_buffer.write_mem(1024, test_row);

  test_row = frame_buffer.read_mem(1024);

  for (pixel_t pixel : test_row) {
    std::cout << "{"  << (int)(pixel[2]) <<
                 ", " << (int)(pixel[1]) <<
                 ", " << (int)(pixel[0]) <<
                 "} ";
  }
  std::cout << std::endl;

  return 0;
}
