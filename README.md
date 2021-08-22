#### VGA CONTROLLER PROJECT

## Aim:
Create a simple controller that can read from inputs and display colours on a monitor

Start at 640x480 (60Hz)

Prototyping on the DE2 board (uses ADV7123 DAC) + Arty A7-100T (uses Digilent VGA PMOD)

##TO DO:
* Move asserts used in vga_controller_tb into a procedure
* Change generic timings in vga_controller_tb to make them full derived from clock
* Modify top level to use a single bit colour enable signal
* Update top level tb to run basic tests.
* Update build scripts to compile, run unit tests and then system tests.
