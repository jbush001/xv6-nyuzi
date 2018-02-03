
// Processor-defined:
#define T_ILLOP          1      // illegal instruction
#define T_PRIVELEGED_OP  2
#define T_EXTERNAL_INT   3
#define T_SYSCALL        4
#define T_ALIGN          5
#define T_PGFLT          6
#define T_TLBMISS        7
#define T_WRFLT          8      // write fault
#define T_SUPERFLT       9      // access to supervisor page
#define T_NOEXEC        10      // attempt to fetch instruction from non-executable
#define T_BRKPT         11      // breakpoint

#define IRQ_TIMER        1
#define IRQ_UART         2
#define IRQ_KBD          3
#define IRQ_VGA          4

