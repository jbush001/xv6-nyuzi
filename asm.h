
// Control register indices
#define CR_CURRENT_HW_THREAD 0
#define CR_TRAP_HANDLER 1
#define CR_TRAP_PC 2
#define CR_TRAP_CAUSE 3
#define CR_FLAGS 4
#define CR_TRAP_ADDR 5
#define CR_TLB_MISS_HANDLER 7
#define CR_SAVED_FLAGS 8
#define CR_CURRENT_ASID 9
#define CR_PAGE_DIR_BASE 10
#define CR_SCRATCHPAD0 11
#define CR_SCRATCHPAD1 12
#define CR_SAVED_SUBCYCLE 13
#define CR_INTERRUPT_MASK 14
#define CR_INTERRUPT_ACK 15
#define CR_INTERRUPT_PENDING 16
#define CR_INTERRUPT_TRIGGER 17

// Flag register bits
#define FLAG_INTERRUPT_EN (1 << 0)
#define FLAG_MMU_EN (1 << 1)
#define FLAG_SUPERVISOR_EN (1 << 2)

// Trap types
#define TT_RESET 0
#define TT_ILLEGAL_INSTRUCTION 1
#define TT_PRIVILEGED_OP 2
#define TT_INTERRUPT 3
#define TT_SYSCALL 4
#define TT_UNALIGNED_ACCESS 5
#define TT_PAGE_FAULT 6
#define TT_TLB_MISS 7
#define TT_ILLEGAL_STORE 8
#define TT_SUPERVISOR_ACCESS 9
#define TT_NOT_EXECUTABLE 10
#define TT_BREAKPOINT 11

#define REG_RA 31
#define REG_SP 30
#define REG_FP 29
#define REG_GP 28

// Must be rounded to a multiple of 64
#define TRAPFRAME_SIZE 192

#define CONTEXT_SIZE 0x840



