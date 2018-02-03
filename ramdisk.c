// Fake IDE disk; stores blocks in memory.
// Useful for running kernel without scratch disk.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "mmu.h"
#include "proc.h"
#include "nyuzi.h"
#include "traps.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

extern uchar _binary_fs_img_start[], _binary_fs_img_size[];

static int disksize;
static uchar *memdisk;

void
block_dev_init(void)
{
  memdisk = _binary_fs_img_start;
  disksize = (uint)_binary_fs_img_size/BSIZE;
}

// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
block_dev_io(struct buf *b)
{
  uchar *p;

  if(!holdingsleep(&b->lock))
    panic("block_dev_io: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("block_dev_io: nothing to do");
  if(b->dev != 1)
    panic("block_dev_io: request not for disk 1");
  if(b->blockno >= disksize)
    panic("block_dev_io: block out of range");

  p = memdisk + b->blockno*BSIZE;

  if(b->flags & B_DIRTY){
    b->flags &= ~B_DIRTY;
    memmove(p, b->data, BSIZE);
  } else
    memmove(b->data, p, BSIZE);
  b->flags |= B_VALID;
}
