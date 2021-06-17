#include <stdlib.h>
#include <time.h>
#include <string.h>
#include "hashmap.h"
#include "jhash.h"

#define OK 0
#define ERROR -1

typedef struct _ListNode
{
	void * data;
	struct _ListNode * next;	
}ListNode;

struct _HashMap
{
	uint32_t initval;
	uint32_t hashmap_size;
	uint32_t (*hash)(void*);
	ListNode ** table;
};

HashMap * init_hashmap(uint32_t size, uint32_t (*hash)(void*))
{
	HashMap * hm;
	hm = (HashMap*)malloc(sizeof(HashMap));
	if(hm == NULL)
		return NULL;
	/* Store values */
	hm->hash = hash;
	hm->hashmap_size = size;
	/* Generate initval */
	srand(time(0));
	hm->initval = (uint32_t)rand();
	/* Allocate the hash table */
	/* NOTE: Using calloc to initialize every entry to NULL/0 */
	hm->table = (ListNode**)calloc(size, sizeof(ListNode*));
	if(hm->table == NULL) {
		free(hm);
		return NULL;
	}
	return hm;
}

void free_hashmap(HashMap * hm, void (*destroy)(void *))
{
	int i;
	ListNode * iter, * aux;

	for(i = 0; i < hm->hashmap_size; i++) {
		/* Delete every item in the list */
		iter = hm->table[i];
		while(iter != NULL) {
			destroy(iter->data);
			aux = iter->next;
			free(iter);
			iter = aux;
		}
	}
	free(hm->table);
	free(hm);
}

int hashmap_add(HashMap * hm, uint8_t * data, int size)
{
	ListNode * new_node, * iter;
	uint32_t index, hash;

	/* Allocate memory for the new entry */
	new_node = (ListNode *)malloc(sizeof(ListNode));
	if(new_node == NULL)
		return ERROR;
	/* Creating a copy of data */
	new_node->data = malloc(size);
	if(new_node->data == NULL) {
		free(new_node);
		return ERROR;
	}
	memcpy(new_node->data, data, size);
	new_node->next = NULL;


	/* Get the entry index in the table */
	hash = hm->hash(new_node->data);
	index = jhash(hash, hm->initval) % hm->hashmap_size;

	/* Insert new node at the end of the table[index] list */
	/* This insertion is used to check duplicates */
	/* Empty list case */
	if(hm->table[index] == NULL) {
		hm->table[index] = new_node;
	}
	/* The list is not empty */
	else {
		iter = hm->table[index];
		if(hm->hash(iter->data) == hash) {
			memcpy(iter->data, new_node->data, size);
			free(new_node->data);
			free(new_node);
			return OK;
		}
		while(iter->next != NULL) {
			/* Check for duplicates */
			if(hm->hash(iter->data) == hash) {
				memcpy(iter->data, new_node->data, size);
				free(new_node->data);
				free(new_node);
				return OK;
			}
			iter->next = new_node;
		}
	}

	return OK;
}

void * hashmap_get(HashMap * hm, uint32_t hash)
{
	ListNode * iter;

	/* Get the head of the list */
	iter = hm->table[jhash(hash, hm->initval) % hm->hashmap_size];

	/* Iterate over the list */
	while(iter != NULL) {
		if(hm->hash(iter->data) == hash)
			return iter->data;
		iter = iter->next;
	}

	return NULL;
}