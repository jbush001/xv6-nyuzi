# Initial process execs /init.
# This code runs in user space.

#include "syscall.h"
#include "traps.h"


.globl _start
_start:
  # exec(init, argv)
  lea s0, init
  lea s1, argv
  move s8, SYS_exec
  syscall

# for(;;) exit();
exit:
  move s0, SYS_exit
  syscall
  b exit

# char init[] = "/init\0";
init:
  .string "/init\0"

# char *argv[] = { init, 0 };
.p2align 2
argv:
  .long init
  .long 0

