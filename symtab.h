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
	i,	//int
	f,	//float
	s,	//string
	v	//void
}val_type;

typedef enum{
	var,
	func,
	proc
}sym_type;

typedef struct{
  char* name;
  val_type type;
  union_val value;
  sym_type sym;
}symbol;

symbol sym_stack[STACK_MAX];
int top;

void init_stack(void);

int *push (char *, val_type, union_val, sym_type);

symbol *pop(void);

symbol *search(char *);

#endif
