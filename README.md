This is a port of the xv6 operating system (https://pdos.csail.mit.edu/6.828/2016/xv6.html)
to the Nyuzi processor (https://github.com/jbush001/NyuziProcessor). See README.xv6 for more
background.

This requires 'nyuzi_emulator' from the Nyuzi repo to be in the PATH.

    export PATH=<path to nyuzi directory>/bin:$PATH

To build:

    make

To run in emulator:

    make run

The system will boot and display a shell prompt. The root directory
contains various tests and utilities.

To run in Verilog simulation (console input does not work in this configuration):

    make vrun

