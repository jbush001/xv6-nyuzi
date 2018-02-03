// Multiprocessor support
// Search memory for MP description structures.
// http://developer.intel.com/design/pentium/datashts/24201606.pdf

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mp.h"
#include "nyuzi.h"
#include "mmu.h"
#include "proc.h"

struct cpu cpus[NCPU];
int ncpu;

// XXX there is no way to detect number of CPUs currently
void
mpinit(void)
{
  ncpu = 4;
}
