#include "symtab.h"

void init_stack(void){
	top = -1;
}

int push(char *_name, val_type _type, union_val _value, sym_type _sym){
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
	symbol t;
	
	if(top<0)
		return NULL;

	//iterate until loop is top-1
	for(t = *sym_stack; loop<top; t = sym_stack[++loop]){
		if(strcmp(t.name, _name) == 0)
			return &sym_stack[loop];
	}
	//check when loop is top
	if(strcmp(t.name, _name)==0)
		return &sym_stack[loop];
	return NULL;
}
