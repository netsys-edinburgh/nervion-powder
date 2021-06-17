#ifndef __JHASH__
#define __JHASH__

/* 
 * Reduced version of Kernel's jhash implementation
 * 2020, Jon Larrea (s2004865@ed.ac.uk)
 */

#include <stdint.h>

/* __jhash_final - final mixing of 3 32-bit values (a,b,c) into c */
#define __jhash_final(a, b, c)			\
{						\
	c ^= b; c -= rol32(b, 14);		\
	a ^= c; a -= rol32(c, 11);		\
	b ^= a; b -= rol32(a, 25);		\
	c ^= b; c -= rol32(b, 16);		\
	a ^= c; a -= rol32(c, 4);		\
	b ^= a; b -= rol32(a, 14);		\
	c ^= b; c -= rol32(b, 24);		\
}

/* An arbitrary initial parameter */
#define JHASH_INITVAL		0xdeadbeef


/**
 * rol32 - rotate a 32-bit value left
 * @word: value to rotate
 * @shift: bits to roll
 */
static inline uint32_t rol32(uint32_t word, unsigned int shift)
{
	return (word << (shift & 31)) | (word >> ((-shift) & 31));
}


/* jhash_3words - hash exactly 3, 2 or 1 word(s) */
static inline uint32_t jhash_3words(uint32_t a, uint32_t b, uint32_t c, uint32_t initval)
{
	a += JHASH_INITVAL;
	b += JHASH_INITVAL;
	c += initval;

	__jhash_final(a, b, c);

	return c;
}

/* Original name: jhash_1word */
static inline uint32_t jhash(uint32_t a, uint32_t initval)
{
	return jhash_3words(a, 0, 0, initval);
}

#endif
