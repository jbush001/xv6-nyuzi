# Initial process execs /init.
# This code runs in user space.

#include "syscall.h"
#include "traps.h"


.globl _start
_start:
  # exec(init, argv)
  lea s0, init
  lea s1, argv
  syscall SYS_exec

# for(;;) exit();
exit:
  syscall SYS_exit
  b exit

# char init[] = "/init\0";
init:
  .string "/init\0"

# char *argv[] = { init, 0 };
.p2align 2
argv:
  .long init
  .long 0

