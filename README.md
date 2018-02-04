This is a port of the xv6 operating system to the Nyuzi processor
(https://github.com/jbush001/NyuziProcessor). See README.xv6 for more
background.

This requires 'nyuzi_emulator' from the Nyuzi repo to be in the PATH.

    export PATH=&lt;path to nyuzi repo&gt;/bin:$PATH

To build and run:

    make run

The system will boot and display a shell prompt. The root directory
contains various tests and utilities.
