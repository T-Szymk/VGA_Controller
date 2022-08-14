
#ifndef SKYLIGHT_BUFF_MODEL_CPP_SPRAM_H
#define SKYLIGHT_BUFF_MODEL_CPP_SPRAM_H

#include "skylight_defs.h"

class SPRAM {

  public:

    SPRAM();
    SPRAM(int width_pixels, int depth_rows);

    void set_memory_zero();
    void set_memory_const(uint8_t init_value); // initalise each pixel to provided argument
    void set_memory_incr(); // pixel values in each row increment along row
    void set_memory_row_address(); // pixel values match row address
    // ToDo: Implement set_memory_from_file(std::string "path to file");

    void write_mem(int address, memory_row_t data);
    memory_row_t read_mem(int address);

  private:

    int mem_width_pixels, mem_depth;
    std::vector<memory_row_t> mem {0};

};


#endif //SKYLIGHT_BUFF_MODEL_CPP_SPRAM_H
