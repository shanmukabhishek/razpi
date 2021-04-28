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
