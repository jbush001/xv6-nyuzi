#include "asm.h"
#include "nyuzi.h"
#include "traps.h"

void timerinit(void)
{
 REGISTERS[REG_TIMER_INTERVAL] = 500000000;
 ioapicenable(IRQ_TIMER, 0);
}