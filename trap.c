#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "nyuzi.h"
#include "traps.h"
#include "spinlock.h"

#define TIMER_INTERVAL 500000   // 100 Hz

struct spinlock tickslock;
uint ticks;
static const char *TRAP_NAMES[] =
{
    "reset",
    "Illegal Instruction",
    "Privileged Op",
    "Interrupt",
    "Syscall",
    "Unaligned Access",
    "Page Fault",
    "TLB Miss",
    "Illegal Store",
    "Illegal Supervisor Page Access",
    "Page Non Executable"
};

void
tvinit(void)
{
  initlock(&tickslock, "time");

  REGISTERS[REG_TIMER_INTERVAL] = TIMER_INTERVAL;
}

static void dispatch_interrupt(int intnum)
{
  switch (intnum)
  {
    case IRQ_UART:
      uartintr();
      break;
    case IRQ_TIMER:
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
      ack_interrupt(IRQ_TIMER);
      if (cpuid() == 0)
        REGISTERS[REG_TIMER_INTERVAL] = TIMER_INTERVAL;

      break;
  }
}

static void dump_trap_frame(const struct trapframe *frame)
{
    int reg;
    int trap_cause = __builtin_nyuzi_read_control_reg(CR_TRAP_CAUSE);
    int trap_type = trap_cause & 0xf;
    unsigned int trap_address = __builtin_nyuzi_read_control_reg(CR_TRAP_ADDR);

    if (trap_type <= TT_NOT_EXECUTABLE)
    {
        cprintf("%s ", TRAP_NAMES[trap_type]);
        if (trap_type == TT_UNALIGNED_ACCESS || trap_type == TT_PAGE_FAULT
                || trap_type == TT_TLB_MISS || trap_type == TT_SUPERVISOR_ACCESS
                || trap_type == TT_ILLEGAL_STORE)
        {
            cprintf("@%x %s %s\n", trap_address,
                (trap_cause & 0x20) ? "dcache" : "icache",
                (trap_cause & 0x10) ? "store" : "load");
        }
    }
    else
        cprintf("Unknown trap cause %x\n", trap_cause);

    cprintf("REGISTERS\n");
    for (reg = 0; reg < 32; reg++)
    {
        if (reg < 10)
            cprintf(" "); // Align single digit numbers

        cprintf("s%d %x ", reg, frame->gpr[reg]);
        if (reg % 8 == 7)
            cprintf("\n");
    }

    cprintf("pc %x ", frame->pc);
    cprintf("Flags: ");
    if (frame->flags & 1)
        cprintf("I");

    if (frame->flags & 2)
        cprintf("M");

    if (frame->flags & 4)
        cprintf("S");

    cprintf(" (%x)\n\n", frame->flags);
}


void
trap(struct trapframe *tf)
{
  int trap_cause = __builtin_nyuzi_read_control_reg(CR_TRAP_CAUSE);
  int intnum = 31 - __builtin_clz(__builtin_nyuzi_read_control_reg(CR_INTERRUPT_PENDING));

  switch(trap_cause & 0xf){
  case TT_SYSCALL:
    if(myproc()->killed)
      exit();
    myproc()->tf = tf;
    myproc()->tf->pc += 4;  // Do before syscall, which will modify if exec
    syscall();
    if(myproc()->killed)
      exit();

    break;

  case TT_INTERRUPT:
    dispatch_interrupt(intnum);
    break;

  default:
    if(myproc() == 0 || tf->flags & FLAG_SUPERVISOR_EN){
      // In kernel, it must be our mistake.
      cprintf("unhandled kernel trap:\n");
      dump_trap_frame(tf);
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("user space process crashed:\n");
    dump_trap_frame(tf);
    myproc()->killed = 1;
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->flags & FLAG_SUPERVISOR_EN) == 0)
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc()
    && myproc()->state == RUNNING
    && (trap_cause & 0xf) == TT_INTERRUPT
    && intnum == IRQ_TIMER) {
    yield();
  }

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->flags & FLAG_SUPERVISOR_EN) == 0)
    exit();
}
