#include "miniuart.h"
#include "memloc.h"
#include "utils.h"

void uart_init() {
  /* Notes:
      - put32, get32 allow us to read and write to a 32 bit register,
        respectively.
  */
  unsigned int selector;

  // GPFSEL1 register controls what devices are connected to what
  // GPIO pins. Grab its value. See notes as to why we want these ones.
  selector = get32(GPFSEL1);

  // Cleans GPIO pin 14
  // Sets bits 12, 13, 14 to 0.
  selector &= ~(7 << 12);
  // Set alt5 for GPIO pin 14
  // This is the key for alt5 (see notes). sets bits 12, 13, 14
  // to 0, 1, 0 (010 is alt fucn 5)
  selector |= 2 << 12;
  // Clean GPIO pin 15. Sets bits 15, 16, 17 to ~(111) = ~7 = 0
  selector &= ~(7 << 15);
  // set alt5 for GPIO pin 15
  selector |= 2 << 15;
  // Write selector to device register GPFSEL1
  put32(GPFSEL1, selector);

  // Next we need to specify pullup/pulldown/neither for the pins.
  // This will stay even after rebooting, so we need to clear it.
  // Since they are always connected, we will not need pullup/pulldown.
  // See notes for why we do it this way.
  put32(GPPUD, 0);
  delay(150);
  put32(GPPUDCLK0, (1 << 14) | (1 << 15));
  delay(150);
  put32(GPPUDCLK0, 0);

  // Now enable mini uart (also enables access to its registers)
  put32(AUX_ENABLES, 1);
  // Disable auto-flow control and disable reciver and transmitter (for now).
  // Auto-flow control is something Raspberry Pi can support, but it's
  // some weird complicated thing that's beyond what our OS will do.
  put32(AUX_MU_CNTL_REG, 0);
  // Disable Mini uart recieve and transmit interrupts. In a later lesson we will
  // use this, but for now it's not something we need. When there is new mini uart
  // data we generate interrupts for it (and presumeably programs to handle them).
  put32(AUX_MU_IER_REG, 0);
  // Enable 8 bit mode. We can do 7 bit mode (mini uart supports both), but we will
  // opt for the "extended" option.
  put32(AUX_MU_LCR_REG, 3);
  // Set RTS line to be always high. Has something to do with auto-flow, which
  // we aren't using so it's set to HIGH (0) all the time.
  put32(AUX_MU_MCR_REG, 0);
  // Set baud rate to 115200. While 115200 is arbitrary, the 270 comes from
  // a formula relating baudrate to system frequency (see notes.md).
  put32(AUX_MU_BAUD_REG, 270);

  // Finally, reenable transmitter and reciver
  put32(AUX_MU_CNTL_REG, 3);
}

void uart_send(char c) {
  while(1) {
    // Loop until device is ready to recieve data. The AUX_MU_LSR
    // register will tell us if the device is ready to recieve
    // data (we check bit 6, so 0010 0000 tells us the FIFO set out
    // last bit and it is ready to recieve a byte).
    if(get32(AUX_MU_LSR_REG) & 0x20)
      break;
  }

  // Place c into the AUX_MU_IO_REG, which will then be sent along the UART
  // FIFO
  put32(AUX_MU_IO_REG, c);
}

void uart_send_string(char* str) {
  int i;
  for(i = 0; str[i] != '\0'; i++)
    uart_send(str[i]);
}

char uart_recv() {
  while(1) {
    if(get32(AUX_MU_LSR_REG) & 0x01)
      break;
  }

  return get32(AUX_MU_IO_REG) & 0xFF;
}
