SECTIONS
{
  /* At the start of this file, the counter is at
     0.*/
  /* At the current location (0), place the .text.boot section.
     Now, take every input file that has a .text.boot section
     (right now only boot.s) and place that here. Thus, we put
     .text.boot at location 0 */
	.text.boot : { *(.text.boot) }
  /* Immediately after this, place the .text section of all input
     files. */
	.text : { *(.text) }
  /* Now place all .rodata after .text */
	.rodata : { *(.rodata) }
  /* Now place the .data section */
	.data : { *(.data) }
  /* Now we want to allign the subsequent sections along 8 byte boundaries */
	. = ALIGN(0x8);
  /* I think this defines the bss_begin symbol as the current location
     counter's value */
	bss_begin = .;
  /* Write the whole bss section */
	.bss : { *(.bss*) }
  /* Now define a bss_end symbol. */
	bss_end = .;
}
