#include "types.h"
#include "nyuzi.h"
#include "defs.h"
#include "kbd.h"

// XXX currently disabled. Although the Nyuzi SoC test environment supports a keyboard,
// it doesn't have text mode display hardware, so I will use the serial port for
// the console.

int
kbdgetc(void)
{
    return 0;
}

void
kbdintr(void)
{
}
