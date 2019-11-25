#ifndef SYMTAB_H
#define SYMTAB_H

#include<stdio.h>
#define STACK_MAX 1000

typedef union{
	int ival;
	int *iptr;
	float fval;
	float *fptr;
	char *sval;
	int (*ifunc)(void *);
	float (*ffunc)(void *);
	void (*proc)(void *);
}union_val;

typedef enum{
	var,
	func,
	proc
}sym_type;

typedef struct{
  char* name;
  int type;		//int: 0, float: 1, int[n]: 2n, float[n]: 1+2n
  union_val value;
  sym_type sym;
}symbol;

// returns value that matches type.
void *ret_val(symbol);

static symbol sym_stack[STACK_MAX];
int top;

void init_stack(void);

int push (char *, int, union_val, sym_type);

symbol *pop(void);

symbol *search(char *);

void print_stack(void);

char *symtostr(symbol);
#endif
