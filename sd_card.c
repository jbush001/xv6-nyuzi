#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "nyuzi.h"
#include "traps.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

static struct spinlock idelock;

#define MAX_RETRIES 100
#define DATA_TOKEN 0xfe

typedef enum
{
  CMD_GO_IDLE_STATE = 0,
  CMD_SEND_OP_COND = 1,
  CMD_SET_BLOCKLEN = 16,
  CMD_READ_SINGLE_BLOCK = 17,
  CMD_WRITE_SINGLE_BLOCK = 24
} sd_command_t;

static void set_cs(int level)
{
  REGISTERS[REG_SD_SPI_CONTROL] = level;
}

static void set_clock_divisor(int divisor)
{
  REGISTERS[REG_SD_SPI_CLOCK_DIVIDE] = divisor - 1;
}

// Transfer a single byte bidirectionally.
static int spi_transfer(int value)
{
  REGISTERS[REG_SD_SPI_WRITE] = value & 0xff;
  while ((REGISTERS[REG_SD_SPI_STATUS] & 1) == 0)
    ;	// Wait for transfer to finish

  return REGISTERS[REG_SD_SPI_READ];
}

static int send_sd_command(sd_command_t command, unsigned int parameter)
{
  int result;
  int retry_count = 0;

  spi_transfer(0x40 | command);
  spi_transfer((parameter >> 24) & 0xff);
  spi_transfer((parameter >> 16) & 0xff);
  spi_transfer((parameter >> 8) & 0xff);
  spi_transfer(parameter & 0xff);
  spi_transfer(0x95);	// Checksum (ignored for all but first command)

  // Read R1 response. 0xff indicates the card is busy.
  do
  {
    result = spi_transfer(0xff);
  }
  while (result == 0xff && retry_count++ < MAX_RETRIES);

  return result;
}

void
bdev_init(void)
{
  int result;

  // Set clock to 200kHz (50Mhz system clock)
  set_clock_divisor(125);

  // After power on, need to send at least 74 clocks with DI and CS high
  // per the spec to initialize (10 bytes is 80 clocks).
  set_cs(1);
  for (int i = 0; i < 10; i++)
    spi_transfer(0xff);

  // Reset the card by sending CMD0 with CS low.
  set_cs(0);
  result = send_sd_command(CMD_GO_IDLE_STATE, 0);

  // The card should have returned 01 to indicate it is in SPI mode.
  if (result != 1)
  {
    if (result == 0xff)
      cprintf("init_sdmmc_device: timed out during reset\n");
    else
      cprintf("init_sdmmc_device: CMD_GO_IDLE_STATE failed: invalid response %02x\n", result);

    return;
  }

  // Send CMD1 and wait for card to initialize. This can take hundreds
  // of milliseconds.
  while (1)
  {
    result = send_sd_command(CMD_SEND_OP_COND, 0);
    if (result == 0)
      break;

    if (result != 1)
    {
      cprintf("init_sdmmc_device: CMD_SEND_OP_COND unexpected response %02x\n", result);
      return;
    }
  }

  // Configure the block size
  result = send_sd_command(CMD_SET_BLOCKLEN, BSIZE);
  if (result != 0)
  {
    cprintf("init_sdmmc_device: CMD_SET_BLOCKLEN unexpected response %02x\n", result);
    return;
  }

  // Increase clock rate to 5 Mhz
  set_clock_divisor(5);
}

// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
bdev_io(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bdev_io: buf not locked");

  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("bdev_io: nothing to do");

  acquire(&idelock);  //DOC:acquire-lock

  if (b->flags & B_DIRTY){
    // write block
    int result;

    result = send_sd_command(CMD_WRITE_SINGLE_BLOCK, b->blockno);
    if (result != 0)
        panic("write_sdmmc_device: CMD_WRITE_SINGLE_BLOCK unexpected response");

    spi_transfer(DATA_TOKEN);
    for (int i = 0; i < BSIZE; i++)
        spi_transfer(b->data[i]);

    // checksum (ignored)
    spi_transfer(0xff);
    spi_transfer(0xff);

    result = spi_transfer(0xff);
    if ((result & 0x1f) != 0x05)
        panic("write_sdmmc_device: write failed");

    b->flags |= B_VALID;
    b->flags &= ~B_DIRTY;
  } else {
    // read block
    int result;
    int data_timeout;

    result = send_sd_command(CMD_READ_SINGLE_BLOCK, b->blockno);
    if (result != 0)
        panic("read_sdmmc_device: CMD_READ_SINGLE_BLOCK unexpected response");

    // Wait for start of data packet
    data_timeout = 10000;
    while (spi_transfer(0xff) != DATA_TOKEN)
    {
        if (--data_timeout == 0)
            panic("read_sdmmc_device: timed out waiting for data token");
    }

    for (int i = 0; i < BSIZE; i++)
       b->data[i] = spi_transfer(0xff);

    // checksum (ignored)
    spi_transfer(0xff);
    spi_transfer(0xff);
    b->flags |= B_VALID;
  }

  release(&idelock);
}
