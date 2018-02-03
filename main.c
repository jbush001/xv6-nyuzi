#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "nyuzi.h"
#include "traps.h"

static void startothers(void);
void mpmain(void)  __attribute__((noreturn));
extern pde_t *kpgdir;
extern char end[]; // first address after kernel loaded from ELF file

// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
  kvmalloc();      // kernel page table
  mpinit();        // detect other processors
  picinit();       // disable pic
  ioapicinit();    // another interrupt controller
  consoleinit();   // console hardware
  uartinit();      // serial port

  pinit();         // process table
  tvinit();        // trap vectors
  binit();         // buffer cache
  fileinit();      // file table
  block_dev_init();       // disk
  startothers();   // start other processors
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
  userinit();      // first user process
  mpmain();        // finish this processor's setup
}

// Common CPU setup code.
void
mpmain(void)
{
  mycpu()->started = 1; // tell startothers() we're up

  // Each CPU needs its own ASID so it won't clobber others
  __builtin_nyuzi_write_control_reg(CR_CURRENT_ASID, cpuid());

  // Need to enable this on all hardware threads
  ioapicenable(IRQ_TIMER, 0);
  scheduler();     // start running processes
}

extern unsigned int mp_init_stack;

// Start the non-boot (AP) processors.
static void
startothers(void)
{
  struct cpu *c;
  char *stack;
  int cpuid;

  for(c = cpus; c < cpus+ncpu; c++){
    cpuid = c - cpus;
    if(c == mycpu())  // We've started already.
      continue;

    // Tell processor what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
    mp_init_stack = (unsigned int) (stack + KSTACKSIZE);

    // write control register to start thread
    REGISTERS[REG_THREAD_RESUME] = 1 << cpuid;

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;

    cprintf("started cpu %d\n", cpuid);
  }
}
