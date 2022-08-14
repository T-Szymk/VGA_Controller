
#ifndef SKYLIGHT_BUFF_MODEL_CPP_PIXELCOUNTER_H
#define SKYLIGHT_BUFF_MODEL_CPP_PIXELCOUNTER_H

#include "skylight_defs.h"

class PixelCounter {
  public:

    PixelCounter() = default;

    void increment();
    void reset();
    int get_line_count() const;
    int get_pixel_count() const;

  private:

    int pixel_counter{0};
    int line_counter{0};

};


#endif //SKYLIGHT_BUFF_MODEL_CPP_PIXELCOUNTER_H
