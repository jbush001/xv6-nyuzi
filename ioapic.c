#include "types.h"
#include "defs.h"
#include "traps.h"
#include "asm.h"

extern void trap_entry();

unsigned int intmask;

void
ioapicinit(void)
{
  __builtin_nyuzi_write_control_reg(CR_TRAP_HANDLER, (int) trap_entry);
  __builtin_nyuzi_write_control_reg(CR_INTERRUPT_TRIGGER, 0x4);
}

void
ioapicenable(int irq, int cpu)
{
  // XXX cpu is ignored
  intmask |= 1 << irq;
  __builtin_nyuzi_write_control_reg(CR_INTERRUPT_MASK, intmask);
}

void ack_interrupt(int irq)
{
  __builtin_nyuzi_write_control_reg(CR_INTERRUPT_ACK, 1 << irq);
}

