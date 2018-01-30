// Intel 8250 serial port (UART).

#include "types.h"
#include "defs.h"
#include "param.h"
#include "traps.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "mmu.h"
#include "proc.h"
#include "nyuzi.h"

#define UART_TX_READY 	(1 << 0)
#define UART_RX_READY 	(1 << 1)
void
uartinit(void)
{
  ioapicenable(IRQ_UART, 0);
}

void
uartputc(int c)
{
  while ((REGISTERS[REG_UART_STATUS] & UART_TX_READY) == 0)
      ;	// Wait for space

  REGISTERS[REG_UART_TX] = c;
}

static int
uartgetc(void)
{
  while ((REGISTERS[REG_UART_STATUS] & UART_RX_READY) == 0)
      ;	// Wait for space

  return REGISTERS[REG_UART_RX];
}

// XXX hook me up in traps
void
uartintr(void)
{
  consoleintr(uartgetc);
}
