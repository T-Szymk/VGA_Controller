#include <iostream>

#include "SPRAM.h"
#include "skylight_defs.h"



void test_SPRAM();

int main() {

  test_SPRAM();

  return 0;
}

void test_SPRAM() {

  SPRAM frame_buffer(PXL_PER_MEM_ROW, FRAME_BUFF_DEPTH);

  frame_buffer.set_memory_zero();

  memory_row_t test_row(PXL_PER_MEM_ROW); // reserve space

  for(int pixel = 0; pixel < PXL_PER_MEM_ROW; pixel++) {
    test_row[pixel] = {42, 69, 200};
  }

  frame_buffer.write_mem(1024, test_row);

  test_row = frame_buffer.read_mem(1024);

  std::cout << "{ ";
  for(int pixel = PXL_PER_MEM_ROW-1; pixel >= 0; pixel--) {
    std::cout << "{"  << (int)(test_row[pixel][2]) <<
              ", " << (int)(test_row[pixel][1]) <<
              ", " << (int)(test_row[pixel][0]) <<
              "} ";
  }
  std::cout << " }" << std::endl;

}
