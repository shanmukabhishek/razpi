# Initial Thoughts
* I'm doing it! I'm writing a bare-metal OS!!!!1!!!!one!!!
* The tutorial does assume some level of expertise on
OS, ARM assembly, Makefiles, etc. Which has helped me
better understand what's going on.
* Tutorial will use headers and won't really explain what
they are all about.

# Notes on Rasberry Pi 3
* SoC (Unsure if the Rasberry Pi 3 is itself an SoC, or
if it uses one, or if the distinction really matters)
* The board used by the Rasberry Pi 3 is a Broadcom
BCM2837.
* The address reserved by the Rasberry Pi 0x3F000000 (and above)
is memory reserved for devices.
  * Physical addresses start at 0x00000000 for RAM.
  * There is a VideoCore section of RAM, but it's only mapped only if the system is configured to support memory mapped display.
    * From the manual, "this is common sense".
    * Mapped onto uncached bus address range starting at 0xC0000000.
    * VideoCore MMU mas ARM physical address space to bus address spaceseen by VideoCore.
  * Physical address range for peripherals is from 0x3F000000 to 0x3FFFFFFF.
    * These are mapped to the peripheral bus address range starting at 0x7E000000.
    * A peripheral advertised at address 0x7E... will have physical address 0x3F...

## How do I access/configure a device?
You need to read or write from a device's register. A device
register is just a 32 bit region of memory. You modify particular
bits of this region to get the desired behavior of the device.
Read the manual on particular bit meaning.

* Memory-mapped device: When CPU access address in memory, may be accessing
RAM or an I/O device.
  * Access to devices via memory-mapped register
    * Access register by accessing a particular address.
    * It's just a 32 bit region in memory.

## Mini UART Device
* Universal Asynchronus Reciever-Transmitter
* Converts bits stored in memory-mapped device registers into
  high and low voltages.
  * Use this fact to transmit signals along ttl-to-serial cable.
### General-Purpose Input/Output (GPIO)
* General uncommitted signal pins used for any kind of I/O the user
wants.
* See the diagram, but we need to activate pins 14/15 on the GPIO board.
  * According to the manuel: "GPIO pins should be set up first before enabling
    UART.
  * Pin 14: maps to TXD0: Primary UART Output
  * Pin 15: maps to RXD0: Primary UART Input
* Rasberry Pi has 26, I think

# Initialize UART
* First we need to activate GPIO pins
	* Each pin can be used by different devices
	* We need to select the pin's `alternative function`.
    * A number from 0 to 5
    * Configures which device we want to connect to the pin.
* We want to turn on pins 14 and 15 (see above) (pg 102 in manual)
* Okay so we want alt function 5 on pins 14, 15 turned on. How to do this?
  * GPFSEL1 register will control this.
* Alt function 5 on each is for TXD1, RXD1 respectively.

# Aside: On the GPFSELn registers
  * General Purpose (IO pin) Function Selection for pin N
  * Bits 0 - 2 for Pin 0
  * Bits 3 - 5 for Pin 1
  * ...
  * On the broadcom board, there are 5 registers which are responsible for
    Certain pins.
    * Register 0: pins 0 - 9
    * Register 1: pins 10 - 19
    * Register 2: pins 20 - 29
    * Register 3: Pins 30 - 39
    * Register 4: Pins 40 - 49
    * Register 5: Pins 50 - 53

  * So, if we want to do work on GPIO pins 14, 15, we need to look at
    register GPFSEL1

# Accessing the pins given the register
* Each pin has a corresponding 3 bits on the register
  * pin 0: bits 0 - 2
  * pin 1: bits 3 - 5
  * ...
* Pin 14 has bits 12 - 14
* Pin 15 has bits 15 - 17
* What you set those 3 bits to will determine the alt-function for that pin.
  * 000 - input
  * 001 - output
  * 100 - alt func 0
  * 101 - alt func 1
  * 110 - alt func 2
  * 111 - alt func 3
  * 011 - alt func 4
  * 010 - alt func 5

## Aside: Pull up and Pull down
* When a circuit is closed, signals along it should go from source to destination
  * (Think a button)
* So when a circuit is closed, the signal should be high
* When it is open/broken, it should be low
* It's not, due to environmental interference
  * Its state is "floating", neither high nor low.

* When circuit is connected to 3.3v GPIO pin, it will be high when
  closes, and floating when open
* When circuit is connected to ground, it will be low when connected
  and floating when open
* For whichever case you've got, you need to "pull down" (force to low)
  or "pull up" (force to high)

## Dealing with pull up/pull down in Rasberry Pi
* We need to deal with this in the Rasberry Pi.
* Broadcom has the following algorithm:
  1. Write to GPPUD to set either pull up, pull down, or neither
  2. Wait 150 clock cycles (provides required set-up time for control signal)
  3. Write to GPPUDCLK0/1 to clock control signal into GPIO pads you want to modify
     (Only pads that recieve a clock will be modified). The rest retain their
     state.
  4. Wait another 150 clock cylces (provides required hold time for the control
     signal
  5. Write to GPPUD to remove control signal
  6. Write to GPPUDCLK0/1 to remove clock
* Use GPPUDCLK0 for pins 0-31, and GPPUDCLK1 for pins 32-53

## Initializing Miniuart itself
* First, to use Auxillery Peripherals (SPI masters + Miniuart), need to 
  enable `AUX_ENABLES`.
* Then disable `AUX_MU_CNTL` to turn off extra Mini Uart Extra control.
  For our OS these are frivolous features and also require extra GPIO pins
  which we haven't. This also disables auto-flow control, which I don't
  really know what that is.
* Then we disable `AUX_MU_IER_REG`, which disables generating MiniUART interrupts.
  We will use this later, but not right now.
* Then we choose the Mini UART line data format. It can be either 7-bit mode
  (00 = 0) or 8-bit mode (11 = 3)
* We set `AUX_MU_LCR_REG` to 3 to enable 8bit mode. The first 2 bits of this
  register control the bit mode (00 for 7 or 11 = 3 for 8).
* Then we disable `AUX_MU_MCR_REG` by setting this to 0. Having the whole
  register be 0 will set `UART1_RTS` line to high. It's used for flow control,
  so we don't need it.

### Aside: Baudrate
* Baudrate controls the rate at which information is propagated in a 
  communication channel.
* Computed according to the equation:
  `baudrate = system_clock_freq / (8 * (baudrate_reg + 1))`
* `system_clock_freq = 250 MHz`
* For whatever reason, we want a baudrate of 115200 (bits/second).
* Thus `0.1152 Mb/s = 250 MHz / (8 * (baudrate_reg + 1))`
* Solve for `baudrate_reg` and get  `270 Baud`
