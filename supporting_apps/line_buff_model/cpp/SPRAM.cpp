
#include "SPRAM.h"

SPRAM::SPRAM() : mem_width_pixels(7), mem_depth(1024) {
  mem.reserve(this->mem_depth);
}

SPRAM::SPRAM(int width_pixels, int depth_rows) :
  mem_width_pixels(width_pixels),
  mem_depth(depth_rows) {

  mem.reserve(this->mem_depth);
}

void SPRAM::set_memory_zero() {
  for(int row = 0; row < this->mem_depth; row++) {
    memory_row_t tmp_row(PXL_PER_MEM_ROW);
    for(int pixel = 0; pixel < PXL_PER_MEM_ROW; pixel++) {
      pixel_t tmp_pixel = {0, 0, 0};
      tmp_row[pixel] = tmp_pixel;
    }
    this->mem[row] = tmp_row;
  }
}

void SPRAM::set_memory_const(const uint8_t init_value) {
  for(int row = 0; row < this->mem_depth; row++) {
    memory_row_t tmp_row(PXL_PER_MEM_ROW);
    for(int pixel = 0; pixel < PXL_PER_MEM_ROW; pixel++) {
      pixel_t tmp_pixel = {init_value, init_value, init_value};
      tmp_row[pixel] = tmp_pixel;
    }
    mem[row] = tmp_row;
  }
}


void SPRAM::set_memory_incr() {
  for(int row = 0; row < this->mem_depth; row++) {
    memory_row_t tmp_row(PXL_PER_MEM_ROW);
    uint8_t init_value = 0;
    for(int pixel = 0; pixel < PXL_PER_MEM_ROW; pixel++) {
      pixel_t tmp_pixel = {init_value, init_value, init_value};
      tmp_row[pixel] = tmp_pixel;
      init_value++;
    }
    mem[row] = tmp_row;
  }
}

void SPRAM::set_memory_row_address() {
  for(int row = 0; row < this->mem_depth; row++) {
    memory_row_t tmp_row(PXL_PER_MEM_ROW);
    uint8_t init_value = row % 256;
    for(int pixel = 0; pixel < PXL_PER_MEM_ROW; pixel++) {
      pixel_t tmp_pixel = {init_value, init_value, init_value};
      tmp_row[pixel] = tmp_pixel;
    }
    mem[row] = tmp_row;
  }
}

void SPRAM::write_mem(const int address, const memory_row_t data) {
  // only write data if it is the correct size
  assert(data.size() == this->mem_width_pixels);
  // only write data if address is valid
  assert(address < this->mem_depth);
  mem[address] = data;
}

memory_row_t SPRAM::read_mem(const int address) {
  // only read data if address is valid
  assert(address < this->mem_depth);
  return mem[address];
}