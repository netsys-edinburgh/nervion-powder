#ifndef __HASHMAP__
#define __HASHMAP__

#include <stdint.h>

#define OK 0
#define ERROR -1

typedef struct _HashMap HashMap;

HashMap * init_hashmap(uint32_t size, uint32_t (*hash)(void*));
void free_hashmap(HashMap * hm, void (*destroy)(void *));
int hashmap_add(HashMap * hm, uint8_t * data, int size);
void * hashmap_get(HashMap * hm, uint32_t hash);

#endif