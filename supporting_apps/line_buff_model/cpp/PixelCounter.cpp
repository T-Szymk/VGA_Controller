
#include "PixelCounter.h"

void PixelCounter::increment() {
  if(this->pixel_counter == (TOTAL_PIXELS_PER_LINE-1)) {
    this->pixel_counter = 0;
    if(this->line_counter == (TOTAL_LINES_PER_FRAME-1)) {
      this->line_counter = 0;
    } else {
      this->line_counter++;
    }
  } else {
    this->pixel_counter++;
  }
}

void PixelCounter::reset() {
  this->pixel_counter = 0;
  this->line_counter = 0;
}

int PixelCounter::get_line_count() const {
  return this->line_counter;
}

int PixelCounter::get_pixel_count() const {
  return this->pixel_counter;
}