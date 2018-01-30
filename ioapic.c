#include "types.h"
#include "defs.h"
#include "traps.h"
#include "asm.h"

extern void trap_entry();

void
ioapicinit(void)
{
  __builtin_nyuzi_write_control_reg(CR_INTERRUPT_TRIGGER, 0x6);
}

void
ioapicenable(int irq, int cpu)
{
  if (cpu != cpuid())
    panic("can't enable interrupt on other CPU");

  __builtin_nyuzi_write_control_reg(CR_TRAP_HANDLER, (int) trap_entry);

  __builtin_nyuzi_write_control_reg(CR_INTERRUPT_MASK,
    __builtin_nyuzi_read_control_reg(CR_INTERRUPT_MASK) | (1 << irq));
}
