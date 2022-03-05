#### VGA CONTROLLER PROJECT

## Aim:
Create a simple controller that can read from inputs and display colours on a monitor

Start at 640x480 (60Hz)

Arty A7-100T (uses Digilent VGA PMOD)

#### _TO DO_:
* Replace colour generator with memory block + controller and test.
		+ First start using a BRAM (accessed via AXI)
		+ Replace BRAM with DDR MIG (accessed via AXI)
* Insert register interface to make operation speeds configurable.
* Update build scripts to compile, run unit tests and then system tests.


