# The xv6 kernel starts executing in this file. This file is linked with
# the kernel C code, so it can refer to kernel symbols such as main().
# The boot block (bootasm.S and bootmain.c) jumps to entry below.

#include "asm.h"
#include "memlayout.h"
#include "mmu.h"
#include "param.h"


# By convention, the _start symbol specifies the ELF entry point.
# Since we haven't set up virtual memory yet, our entry point is
# the physical address of 'entry'.
.globl _start
_start = V2P_WO(entry)

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
    # Set up TLB miss handler. This is a physical address, so need
    # to mask off virtual address to convert.
    # XXX can't really use V2P here, because it doesn't work with lea
    lea s0, tlb_miss_handler
    li s1, 0xffffff
    and s0, s0, s1      // Mask off high bits
    setcr s0, CR_TLB_MISS_HANDLER

    # Set up page directory
    lea s0, entrypgdir

    # Convert to physical address
    li s1, 0xffffff
    and s0, s0, s1      // Mask off high bits
    setcr s0, CR_PAGE_DIR_BASE

    # Turn on paging.
    move s0, FLAG_MMU_EN | FLAG_SUPERVISOR_EN
    setcr s0, CR_FLAGS

    # Branch to flush pipeline and ensure paging is on
    b 1f
1:

    # All processors start here, determine if I'm the main processor
    getcr s0, 0
    bnz s0, start_thread_n

    # Set up the stack pointer.
    lea sp, stack
    add_i sp, sp, KSTACKSIZE

    # Jump to main(), and switch to executing at
    # high addresses. The indirect call is needed because
    # the assembler produces a PC-relative instruction
    # for a direct jump.
    lea s0, main
    b s0

start_thread_n:
    # Set up the stack pointer. This is set up by startothers, which
    # waits until this has started before starting the next.
    lea s0, mp_init_stack
    load_32 sp, (s0)
    add_i sp, sp, KSTACKSIZE

    lea s0, mpmain
    b s0

.globl mp_init_stack
mp_init_stack: .long  0

.comm stack, KSTACKSIZE, 64

.align 0x1000
entrypgtab:
  .long 0x00000000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00001000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00002000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00003000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00004000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00005000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00006000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00007000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00008000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00009000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0000a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0000b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0000c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0000d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0000e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0000f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00010000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00011000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00012000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00013000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00014000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00015000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00016000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00017000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00018000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00019000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0001a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0001b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0001c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0001d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0001e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0001f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00020000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00021000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00022000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00023000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00024000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00025000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00026000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00027000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00028000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00029000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0002a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0002b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0002c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0002d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0002e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0002f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00030000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00031000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00032000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00033000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00034000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00035000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00036000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00037000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00038000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00039000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0003a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0003b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0003c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0003d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0003e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0003f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00040000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00041000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00042000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00043000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00044000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00045000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00046000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00047000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00048000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00049000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0004a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0004b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0004c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0004d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0004e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0004f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00050000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00051000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00052000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00053000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00054000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00055000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00056000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00057000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00058000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00059000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0005a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0005b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0005c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0005d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0005e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0005f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00060000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00061000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00062000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00063000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00064000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00065000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00066000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00067000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00068000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00069000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0006a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0006b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0006c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0006d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0006e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0006f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00070000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00071000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00072000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00073000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00074000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00075000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00076000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00077000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00078000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00079000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0007a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0007b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0007c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0007d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0007e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0007f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00080000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00081000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00082000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00083000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00084000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00085000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00086000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00087000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00088000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00089000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0008a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0008b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0008c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0008d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0008e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0008f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00090000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00091000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00092000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00093000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00094000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00095000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00096000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00097000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00098000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x00099000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0009a000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0009b000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0009c000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0009d000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0009e000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x0009f000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000a9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000aa000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ab000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ac000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ad000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ae000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000af000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000b9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ba000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000bb000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000bc000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000bd000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000be000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000bf000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000c9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ca000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000cb000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000cc000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000cd000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ce000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000cf000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000d9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000da000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000db000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000dc000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000dd000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000de000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000df000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000e9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ea000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000eb000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ec000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ed000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ee000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ef000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000f9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000fa000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000fb000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000fc000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000fd000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000fe000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0x000ff000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G

.align 0x1000
iopgtab:
  .space 0x1000 - (16 * 4)
  .long 0xffff0000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff1000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff2000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff3000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff4000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff5000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff6000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff7000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff8000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffff9000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffffa000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffffb000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffffc000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffffd000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xffffe000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G
  .long 0xfffff000 | PTE_P | PTE_W | PTE_X | PTE_S | PTE_G

.align 0x1000
entrypgdir:
  .long entrypgtab - 0x80000000 + (PTE_P | PTE_W | PTE_X | PTE_S | PTE_G)
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

  .long entrypgtab - 0x80000000 + (PTE_P | PTE_W | PTE_X | PTE_S | PTE_G)

  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

  .long iopgtab - 0x80000000 + (PTE_P | PTE_W | PTE_X | PTE_S | PTE_G)



