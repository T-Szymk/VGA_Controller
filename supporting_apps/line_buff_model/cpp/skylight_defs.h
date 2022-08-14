//
// Created by tom on 14/08/22.
//

#ifndef SKYLIGHT_BUFF_MODEL_CPP_SKYLIGHT_DEFS_H
#define SKYLIGHT_BUFF_MODEL_CPP_SKYLIGHT_DEFS_H

#include <array>
#include <vector>
#include <cassert>
#include <cstdint>

using pixel_t      = std::array<uint8_t, 3>;
using memory_row_t = std::vector<pixel_t>;

constexpr int TOTAL_PIXELS_PER_LINE = (16 + 640 + 48 + 96);
constexpr int TOTAL_LINES_PER_FRAME  = (10 + 480 + 33 + 2);

constexpr int FRAME_WIDTH  = 640;
constexpr int FRAME_HEIGHT = 480;

constexpr int TILE_SIZE = 4;
constexpr int TOTAL_FRAME_PIXELS = FRAME_HEIGHT * FRAME_WIDTH;
constexpr int TOTAL_TILES  = TOTAL_FRAME_PIXELS / (TILE_SIZE * TILE_SIZE);
constexpr int PXL_PER_MEM_ROW = 7;
constexpr int FRAME_BUFF_DEPTH = (TOTAL_TILES / PXL_PER_MEM_ROW);



#endif //SKYLIGHT_BUFF_MODEL_CPP_SKYLIGHT_DEFS_H
