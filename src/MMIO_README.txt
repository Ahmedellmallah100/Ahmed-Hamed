8-bit RISC CPU - Peripheral Upgrade

Added peripherals:
1) UART TX: 8-N-1, approximately 115200 baud at 10 MHz clock.
2) GPIO output register.
3) Free-running 8-bit timer with enable control.
4) Software-selectable output mode.

Memory map:
0x00-0x0F : existing RAM
0x10       : UART_TX (write byte; read bit0 = busy)
0x11       : GPIO_OUT (read/write)
0x12       : TIMER_CTL (bit0 enable)
0x13       : TIMER_CNT (read-only)
0x14       : OUTPUT_MODE (00 CPU_OUT, 01 GPIO, 10 UART_TX, 11 TIMER_CNT)
0x15       : GPIO_IN (reserved, reads 0)

How to use UART:
- Load 0x10 into a register using LI.
- Put the character byte in another register.
- Execute SW with zero offset using the address register as rs1 and data register as rs2.
- Set OUTPUT_MODE to 2 first if the physical TX waveform is to appear on uo_out[0].

How to use GPIO:
- Write a byte to 0x11.
- Write 1 to 0x14 to expose GPIO_OUT on uo_out.

How to use Timer:
- Write 1 to 0x12 to enable it.
- Read 0x13 for the current count.
- Write 3 to 0x14 to expose the timer count on uo_out.

Important:
The existing CPU uses a two-phase state machine, so an instruction is executed every other clock.
The peripheral block is MMIO and does not change the existing RAM address space.
UART timing assumes a 10 MHz clock. Change CLKS_PER_BIT in CPU_Core/UART_TX if your clock differs.
