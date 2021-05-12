#include "miniuart.h"

void kernel_main() {
  char c;
  uart_init();
  uart_send_string("Hello, world!\r\n");
  uart_send_string("Please enter a character\r\n");
  c = uart_recv();
  uart_recv();
  uart_send_string("Your character is:");
  uart_send(c);

  while(1) {
    uart_send(uart_recv());
  }
}
