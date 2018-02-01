#include "asm.h"
#include "nyuzi.h"
#include "traps.h"

void timerinit(void)
{
 REGISTERS[REG_TIMER_INTERVAL] = 5000000;
 ioapicenable(IRQ_TIMER, 0);
}