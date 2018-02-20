                    .globl _start
_start:
                    # Load global pointer
                    movehi gp, hi(_GLOBAL_OFFSET_TABLE_)
                    or gp, gp, lo(_GLOBAL_OFFSET_TABLE_)

                    call main
                    call exit