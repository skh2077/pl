#ifndef SYMTAB_H
#define SYMTAB_H

#include<stdio.h>
#define STACK_MAX 1000

typedef union{
	int ival;
	float fval;
	char *sval;
}union_val;

typedef enum{
	var,
	func,
	proc
}sym_type;

typedef struct{
  char* name;
  int type;		//int: 0, float: 1, int array: 2, float array: 3
  union_val value;
  sym_type sym;
}symbol;

static symbol sym_stack[STACK_MAX];
int top;

void init_stack(void);

int push (char *, int, union_val, sym_type);

symbol *pop(void);

symbol *search(char *);

void print_stack(void);

char *symtostr(symbol);
#endif
