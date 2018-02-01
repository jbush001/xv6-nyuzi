// This is actually an SD card driver

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
  SD_CMD_RESET = 0,
  SD_CMD_INIT = 1,
  SD_CMD_SET_BLOCK_LEN = 0x16,
  SD_CMD_READ_SINGLE_BLOCK = 0x17,
  SD_CMD_WRITE_SINGLE_BLOCK = 0x24
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
block_dev_init(void)
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
  result = send_sd_command(SD_CMD_RESET, 0);

  // The card should have returned 01 to indicate it is in SPI mode.
  if (result != 1)
  {
    if (result == 0xff)
      cprintf("init_sdmmc_device: timed out during reset\n");
    else
      cprintf("init_sdmmc_device: SD_CMD_RESET failed: invalid response %02x\n", result);

    return;
  }

  // Send CMD1 and wait for card to initialize. This can take hundreds
  // of milliseconds.
  while (1)
  {
    result = send_sd_command(SD_CMD_INIT, 0);
    if (result == 0)
      break;

    if (result != 1)
    {
      cprintf("init_sdmmc_device: SD_CMD_INIT unexpected response %02x\n", result);
      return;
    }
  }

  // Configure the block size
  result = send_sd_command(SD_CMD_SET_BLOCK_LEN, BSIZE);
  if (result != 0)
  {
    cprintf("init_sdmmc_device: SD_CMD_SET_BLOCK_LEN unexpected response %02x\n", result);
    return;
  }

  // Increase clock rate to 5 Mhz
  set_clock_divisor(5);
}

// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
block_dev_io(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("block_dev_io: buf not locked");

  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("block_dev_io: nothing to do");

  acquire(&idelock);  //DOC:acquire-lock

  if (b->flags & B_DIRTY){
    // write block
    int result;

    result = send_sd_command(SD_CMD_WRITE_SINGLE_BLOCK, b->blockno);
    if (result != 0)
        panic("write_sdmmc_device: SD_CMD_WRITE_SINGLE_BLOCK unexpected response");

    spi_transfer(DATA_TOKEN);
    for (int i = 0; i < BSIZE; i++)
        spi_transfer(b->data[i]);

    // checksum (ignored)
    spi_transfer(0xff);
    spi_transfer(0xff);

    result = spi_transfer(0xff);
    if ((result & 0x1f) != 0x05)
        panic("write_sdmmc_device: write failed");
  } else {
    // read block
    int result;
    int data_timeout;

    result = send_sd_command(SD_CMD_READ_SINGLE_BLOCK, b->blockno);
    if (result != 0)
        panic("read_sdmmc_device: SD_CMD_READ_SINGLE_BLOCK unexpected response");

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
  }

  release(&idelock);
}
