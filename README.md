# MIPSelbrot
An interactive mandelbrot fractal viewer written in MIPS

## Screenshots

![1](media/screenshot1.png)

## Setup
This program was designed to run in the Mars emulator.

- Open the Bitmap Display
- Set the Unit Width and Height to 8
- Set the Display Width and Height to 512
- Set the Base Address for Display to `0x10008000 ($gp)`
- Open the Keyboard and Display MMIO Simulator
- Connect the Bitmap Display and Keyboard Simulator to Mars
- Assemble and Run the program

## Usage
The viewer supports the following features via the keyboard

| Effect | Command |
| --- | --- |
| Translation | Up - "w" <br> Down - "s" <br> Left - "a" <br> Right - "d"|
| Zoom | In - "z" <br> Out - "x" |
| Hue Shift | Up - "o" <br> Down - "l" |
| Brightness Shift | Up - "i" <br> Down - "k" |
| Toggle sound - default is off, causes significant slowdown | "m" |
| Exit | "space" |

Input is accepted between renders. When a render is complete, the top left pixel will flash black and white.

## How does it work?

## Flowchart

![Flowchart](media/flowchart.png)

## Known Issues
- Zooming does not always put you where you wanted to go, you may end up stuck in a long render loop at the center of the fractal
- Toggling the music on causes a slowdown of around 2 orders of magnitude. Asynchronous MIDI cannot be used due to a bug in Mars audio rendering
- Too many hue or brightness shifts in either direction (more than 10) could be irreversible as the hue and brightness coefficients approach and eventually reach 0
