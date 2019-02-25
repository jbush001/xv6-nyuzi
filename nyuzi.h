#include "asm.h"

static inline int
readflags()
{
  return __builtin_nyuzi_read_control_reg(CR_FLAGS);
}

static inline void
cli(void)
{
  __builtin_nyuzi_write_control_reg(CR_FLAGS,
    readflags() & ~FLAG_INTERRUPT_EN);
}

static inline void
sti(void)
{
  __builtin_nyuzi_write_control_reg(CR_FLAGS,
    readflags() | FLAG_INTERRUPT_EN);
}

static inline void
inval_all_tlb(void)
{
    __asm__("tlbinvalall");
}

static inline void
inval_tlb(void *addr)
{
    __asm__("tlbinval %0" : : "s" (addr));
}

// Layout of the trap frame built on the stack by the
// hardware and by trapasm.S, and passed to trap().

struct trapframe {
    unsigned int gpr[32];
    unsigned int pc;
    unsigned int flags;
    unsigned int subcycle;
};


// Memory mapped peripheral registers

static volatile unsigned int * const REGISTERS = (volatile unsigned int*) 0xffff0000;

enum RegisterIndex
{
    REG_RED_LED             = 0x0000 / 4,
    REG_GREEN_LED           = 0x0004 / 4,
    REG_HEX0                = 0x0008 / 4,
    REG_HEX1                = 0x000c / 4,
    REG_HEX2                = 0x0010 / 4,
    REG_HEX3                = 0x0014 / 4,
    REG_UART_STATUS         = 0x0040 / 4,
    REG_UART_RX             = 0x0044 / 4,
    REG_UART_TX             = 0x0048 / 4,
    REG_KB_STATUS           = 0x0080 / 4,
    REG_KB_SCANCODE         = 0x0084 / 4,
    REG_SD_SPI_WRITE        = 0x00c0 / 4,
    REG_SD_SPI_READ         = 0x00c4 / 4,
    REG_SD_SPI_STATUS       = 0x00c8 / 4,
    REG_SD_SPI_CONTROL      = 0x00cc / 4,
    REG_SD_SPI_CLOCK_DIVIDE = 0x00d0 / 4,
    REG_VGA_ENABLE          = 0x0180 / 4,
    REG_VGA_MICROCODE       = 0x0184 / 4,
    REG_VGA_BASE            = 0x0188 / 4,
    REG_VGA_LENGTH          = 0x018c / 4,
    REG_TIMER_INTERVAL      = 0x0240 / 4,
};
