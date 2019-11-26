#include <string.h>
#include "symtab.h"

void *ret_val(symbol *sym){
	if(!sym)
		return (void *)NULL;
	else{
		switch(sym->sym){
			case var:
				if(sym->type == 0)
					return &sym->value.ival;
				else if(sym->type == 1)
					return &sym->value.fval;
				else if(sym->type % 2 == 0)
					return sym->value.iptr;
				else if(sym->type % 2 == 1)
					return sym->value.fptr;
				else
					return (void *)NULL;
			case func:
				if(sym->type == 0)
					return &sym->value.ifunc;
				else if(sym->type == 1)
					return &sym->value.ffunc;
				else
					return (void *)NULL;
			case proc:
				return sym->value.proc;
			default:
				return (void *)NULL;
		}
	}
}

void init_stack(void){
	top = -1;
}

int push(char *_name, int _type, union_val _value, sym_type _sym){
	if(top < STACK_MAX - 1){
		symbol new;
		new.name = _name;
		new.type = _type;
		new.value = _value;
		new.sym = _sym;
		sym_stack[++top] = new;
		return 0;
	}
	return -1;
}

symbol *pop(void){
	if(top<0)
		return NULL;
	else return &sym_stack[top--];
}

symbol *search(char *_name){
	int loop=top;
	
	if(top<0)
		return NULL;

	for(; loop>=0; loop--){
		if(strcmp(sym_stack[loop].name, _name) == 0)
			return &sym_stack[loop];
	}
	return NULL;
}

void print_stack(void){
	int loop=0;
	if (top<0){
		printf("stack is empty\n");
		return;
	}
	for(; loop<=top; loop++){
		symbol sym = sym_stack[loop];
		printf ("stack%d: %s value: %d\n", loop, sym.name, sym.value);
	}
}
