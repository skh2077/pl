#include <string.h>
#include "symtab.h"

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
	int loop=top;
	if (top<0){
		printf("stack is empty\n");
		return;
	}
	for(; loop>=0; loop--){
		symbol sym = sym_stack[loop];
		printf("stack %d -> %s : ", loop, sym.name);
		print_sym(&sym);
		printf("\n");
	}
}

void print_sym(symbol *sym){
	if(!sym)
		return;
	switch(sym->sym){
		case var:
			if(sym->type < 0){
				char *print_str;
				print_str = sym->value.ival == -1 ? "false" : "true";
				printf("%s", print_str);
			}else if(sym->type > 1){
				int loop = 0, arr_size = sym->type / 2;
				printf("[ ");
				if(sym->type % 2 == 0){
					for(; loop < arr_size-1; loop++){
						printf("%d, ", sym->value.iptr[loop]);
					}
					printf("%d ]", sym->value.iptr[arr_size-1]);
				}else{
					for(; loop < arr_size-1; loop++){
						printf("%f, ", sym->value.fptr[loop]);
					}
					printf("%f ]", sym->value.fptr[arr_size-1]);
				}
			}else{
				if(sym->type % 2 == 0)
					printf("%d", sym->value.ival);
				else
					printf("%f", sym->value.fval);
			}
			break;
		default:
			printf("function");
	}	
}
