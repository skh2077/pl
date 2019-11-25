#include <string.h>
#include "symtab.h"

void init_stack(void){
	top = -1;
	print_stack();
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
	int loop=0;
	
	if(top<0)
		return NULL;

	for(; loop<=top; loop++){
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
