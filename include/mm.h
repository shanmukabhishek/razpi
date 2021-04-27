#ifndef _MM_H
#define _NN_H

#define PAGE_SHIFT    12
#define TABLE_SHIFT   9
#define SECTION_SHIFT (PAGE_SHIFT + TABLE_SHIFT)

#define PAGE_SIZE     (1 << PAGE_SHIFT)
#define SECTION_SIZE  (1 << SECTION_SHIFT)

#define LOW_MEM       (SECTION_SIZE << 1) // 2 * section size

#ifndef __ASSEMBLER __

void memzero(const unsigned long src, const unsigned long n);

#endif

#endif
