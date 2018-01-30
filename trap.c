#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "nyuzi.h"
#include "traps.h"
#include "spinlock.h"

struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
  initlock(&tickslock, "time");
}

void
idtinit(void)
{
}

void ack_interrupt(int irq)
{
  __builtin_nyuzi_write_control_reg(CR_INTERRUPT_ACK, 1 << irq);
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
      break;
  }
}

//PAGEBREAK: 41
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
      cprintf("unexpected trap %d from cpu %d pc %x (addr 0x%x)\n",
              trap_cause, cpuid(), tf->pc, __builtin_nyuzi_read_control_reg(CR_TRAP_ADDR));
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d on cpu %d "
            "pc 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, trap_cause,
            cpuid(), tf->pc, __builtin_nyuzi_read_control_reg(CR_TRAP_ADDR));
    myproc()->killed = 1;
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->flags & FLAG_SUPERVISOR_EN) == 0)
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING && intnum == IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->flags & FLAG_SUPERVISOR_EN) == 0)
    exit();
}
