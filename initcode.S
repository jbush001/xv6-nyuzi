# Initial process execs /init.
# This code runs in user space.

#include "syscall.h"
#include "traps.h"


# exec(init, argv)
.globl start
start:
  move s0, SYS_exec
  lea s1, init
  lea s2, argv
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

