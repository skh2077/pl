#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdio.h>
#include <stdint.h>
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
	boolean,
	var,
	func,
	proc
}sym_type;

typedef struct{
  char* name;	//if name == null then array element or boolean
  int type;		//true: not 0, false/int: 0, float: 1, int[n]: 2n, float[n]: 1+2n
  union_val value;
  sym_type sym;
}symbol;

typedef enum{
	_true = -100,
	_false,
	_NULL = 0,
	_int,
	_float,
	_int_elem,
	_float_elem,
	_int_arr,
	_float_arr,
	_proc,
	_func,
	_unknown
}_type;


static symbol sym_stack[STACK_MAX];
int top;

void init_stack(void);

int sym_stack_is_full(void);

int push (char *, int, union_val, sym_type);

symbol *pop(void);

symbol *search(char *);

int8_t _typeof(symbol *);

char *_typeof_str(symbol *);

void print_sym(symbol*);

void print_stack(void);
#endif
