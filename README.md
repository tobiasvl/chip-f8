# CHIP-F8

A CHIP-8 interpreter for the Fairchild Channel F (Video Entertainment System) video game console.

## Build

Using [dasm](https://dasm-assembler.github.io/):

    dasm chip-f8.asm -f3 -ochip-f8.bin

## Run

Using [MESS](http://mess.redump.net/):

    messd channelf -cartridge chip-f8.bin -w -effect sharp -r 640x480 -ka
