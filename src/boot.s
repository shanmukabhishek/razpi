#include "mm.h"

// Says "Everything should go in the .text.boot section.
// In our linker.ld, this is the first section in the image.
// So this is the first bit of code to be executed.
.section ".text.boot"

.globl _start

// This code is executed on all cores (4 of them on the
// rasberry pi). We only want one to execute.
_start:
  // Moves mpidr_el1 into x0. For this core, it will
  // grab the current id.
  mrs x0, mpidr_el1
  // The first 8 bits tell us what core we are on, so
  // we apply the FF flag to zero out everything else
  // except those bits.
  and x0, x0, #0xFF
  // If the core is 0, go to master.
  cbz x0, master
  // Otherwise just loop.
  b proc_hang

proc_hang:
  b proc_hang

master:
  // Move the address of the start of the bss section
  // into x0.
  adr x0, bss_begin
  // Move the end of the bss section into x1.
  adr x1, bss_end
  // Subtract the two and put the result into x1.
  sub x1, x1, x0
  // Execute memzero (with link). When execution
  // of memzero is done, we will continue on to the
  // next instruction here.
  // Note that calling convention for arguments is
  // x0 - x6. So we give this x0 - the start of bss,
  // and x1 - the size of it. 
  bl memzero

  // Set the stack pointer to LOW_MEM (defined in mm.h).
  mov sp, #LOW_MEM
  bl kernel_main
  b hang
