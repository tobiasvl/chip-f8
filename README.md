# CHIP-F8

**A CHIP-8 interpreter for the Fairchild Channel F (Video Entertainment System).**

## Build Instructions

To build the project, use the **dasm** assembler:

```bash
dasm chip-f8.asm -f3 -ochip-f8.bin

## Run

Using [MESS](http://mess.redump.net/):

messd channelf -cartridge chip-f8.bin -w -effect sharp -r 640x480 -ka
