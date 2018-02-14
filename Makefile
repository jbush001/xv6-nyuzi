OBJS = \
	bio.o\
	console.o\
	exec.o\
	file.o\
	fs.o\
	sd_card.o\
	kalloc.o\
	kbd.o\
	log.o\
	main.o\
	mp.o\
	pipe.o\
	proc.o\
	sleeplock.o\
	spinlock.o\
	string.o\
	swtch.o\
	syscall.o\
	sysfile.o\
	sysproc.o\
	trapasm.o\
	trap.o\
	uart.o\
	vm.o\

TOOLROOT=/usr/local/llvm-nyuzi/bin/
CC = $(TOOLROOT)/clang
AS = $(TOOLROOT)//clang
LD = $(TOOLROOT)//ld.lld
OBJDUMP = $(TOOLROOT)/llvm-objdump
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O3 -Wall -g

all: kernel.hex fs.img

kernel.hex: $(OBJS) entry.o initcode
	$(LD) $(LDFLAGS) -T kernel.ld -o kernel.elf --image-base=0x80000000 entry.o $(OBJS) -format binary initcode
	$(OBJDUMP) -d kernel.elf > kernel.lst
	$(TOOLROOT)/elf2hex -b 0x80000000 -o kernel.hex kernel.elf

initcode: initcode.S
	$(CC) $(CFLAGS) -nostdinc -I. -c initcode.S
	$(LD) $(LDFLAGS) --oformat binary --image-base=0 -o initcode initcode.o

# Run in emulator
run: fs.img kernel.hex
	nyuzi_emulator -b fs.img kernel.hex

# Run in verilator
vrun: fs.img kernel.hex
	nyuzi_vsim +block=fs.img +bin=kernel.hex

# kernelmemfs is a copy of kernel that maintains the
# disk image in memory instead of writing to a disk.
# This is not so useful for testing persistent storage or
# exploring disk buffering implementations, but it is
# great for testing the kernel on real hardware without
# needing a scratch disk.
MEMFSOBJS = $(filter-out sd_card.o,$(OBJS)) ramdisk.o
kernelmemfs: $(MEMFSOBJS) entry.o initcode fs.img
	$(LD) $(LDFLAGS) -T kernel.ld -o kernelmemfs.elf --image-base=0x80000000 entry.o $(MEMFSOBJS) -format binary initcode fs.img
	$(OBJDUMP) -S kernelmemfs.elf > kernelmemfs.lst
	$(TOOLROOT)/elf2hex -b 0x80000000 -o kernelmemfs.hex kernelmemfs.elf

runmemfs: kernelmemfs.hex
	nyuzi_emulator kernelmemfs.hex


ULIB = ulib.o usys.o printf.o umalloc.o

_%: %.o $(ULIB)
	$(LD) $(LDFLAGS) -e main -o $@ $^
	$(OBJDUMP) -S $@ > $*.lst
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $*.sym

_forktest: forktest.o $(ULIB)
	# forktest has less library code linked in - needs to be small
	# in order to be able to max out the proc table.
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o _forktest forktest.o ulib.o usys.o
	$(OBJDUMP) -S _forktest > forktest.lst

mkfs: mkfs.c fs.h
	gcc -Werror -Wall -o mkfs mkfs.c

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o

UPROGS=\
	_cat\
	_echo\
	_forktest\
	_grep\
	_init\
	_kill\
	_ln\
	_ls\
	_mkdir\
	_rm\
	_sh\
	_stressfs\
	_usertests\
	_wc\
	_zombie

fs.img: mkfs $(UPROGS) FORCE
	./mkfs fs.img $(UPROGS) README.xv6

-include *.d

clean:
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*.o *.d *.lst *.sym \
	initcode initcode.out kernel xv6.img fs.img kernelmemfs mkfs \
	.gdbinit \
	$(UPROGS)

FORCE:
