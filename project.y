%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	extern int yylineno;
	int yylex();
	void yyerror (char const *);
	FILE *yyin;

	struct val_node{
		char *value;
		struct val_node *next;
	};
%}
%code requires{
	#include "symtab.h"
}
%union yytype{
	int ival;
	float fval;
	char *sval;
	struct val_node *val_node_ptr;
	symbol *symbol_ptr;
}
%start program

%locations

%token <sval> ID KW_MAIN KW_FUNC KW_PROC KW_BEGIN KW_END KW_IF KW_THEN KW_ELSE KW_ELIF KW_NOP KW_FOR KW_WHILE KW_RETURN KW_PRINT KW_IN OP_ADD OP_SUB OP_MUL OP_DIV OP_LT OP_LE OP_GT OP_GE OP_EQUAL OP_NOTEQ OP_NEG DL_SMCOLON DL_DOT DL_COMMA DL_ASSIGN DL_LPAREN DL_RPAREN DL_LBRACK DL_RBRACK DL_COLON
%token <ival> INTEGER KW_INT KW_FLOAT
%type <ival> type standard_type
%token <fval> FLOAT
%type <val_node_ptr> identifier_list
%type <symbol_ptr> factor variable
%precedence DL_COLON
%precedence KW_ELIF
%precedence KW_ELSE
%right KW_IN

%left OP_ADD OP_SUB OP_MUL OP_DIV
%%

program:
	%empty
	| KW_MAIN ID DL_SMCOLON declarations subprogram_declarations compound_statement 
	;

declarations:	
	type identifier_list DL_SMCOLON declarations	{
		struct val_node *temp_node;
		for (temp_node=$2; temp_node; temp_node = temp_node->next){
			union_val temp;
			temp.ival = 0;
			push(temp_node->value, $1, temp, var);
			free(temp_node);
		}
	}
	| %empty
	;

subprogram_declarations:
	subprogram_declaration subprogram_declarations
	| %empty	
	;

compound_statement:
	KW_BEGIN statement_list KW_END
	;

type:
	standard_type
	| standard_type DL_LBRACK INTEGER DL_RBRACK
	;

identifier_list:
	ID									{
		struct val_node *new = (struct val_node *)malloc(sizeof(struct val_node));
		new->value = $1;
		new->next = NULL;
		$$ = new;
	}
	| ID DL_COMMA identifier_list		{
		struct val_node *list, *new;
		list = $3;
		new = (struct val_node *)malloc(sizeof(struct val_node));
		new->value = $1;
		new->next = list;
		$$ = new;
	}
	;

standard_type:
	KW_INT								{$$=0;}
	| KW_FLOAT							{$$=1;}
	;

subprogram_declaration:
	subprogram_head declarations compound_statement
	;

subprogram_head:
	KW_FUNC ID arguments DL_COLON standard_type DL_SMCOLON
	| KW_PROC ID arguments DL_SMCOLON
	;

arguments:
	DL_LPAREN parameter_list DL_RPAREN
	| %empty
	;

parameter_list:
	identifier_list DL_COLON type
	| identifier_list DL_COLON type DL_SMCOLON parameter_list
	;

statement_list:
	statement
	| statement DL_SMCOLON statement_list
	;

statement:
	variable DL_ASSIGN expression
	| print_statement
	| procedure_statement
	| compound_statement
	| if_statement
	| while_statement
	| for_statement
	| KW_RETURN expression
	| KW_NOP
	;

variable:
	ID										{
		symbol *null = NULL, *temp;
		temp = search($1);
		if(!temp){
			char *errmsg = strcat($1, " is not defined.");
			yyerror(errmsg);
			$$ = null;
		}
		else if(temp->sym == var){
			if(temp->type==0 || temp->type==1){
				$$ = temp;
			}
			else{
				char *errmsg = strcat($1, " is array.");
				yyerror(errmsg);
				$$ = null;
			}
		}
		else{
			char *errmsg = strcat($1, " is function.");
			yyerror(errmsg);
			$$ = null;
		}
	}
	| ID DL_LBRACK expression DL_RBRACK	{
		symbol *null = NULL, *temp, *ret;
		temp = search($1);
		//TODO: checking whether $3 is ival.
		if(!temp){
			char *errmsg = strcat($1, " is not defined.");
			yyerror(errmsg);
			$$ = null;
		}
		else if(temp->sym == var){
			int type = temp->type % 2, arr_size = temp->type / 2;
			if(arr_size < 1){
				char *errmsg = strcat($1, " is not array.");
				yyerror(errmsg);
				$$ = null;
			}
			else if($<ival>3 < 0 || $<ival>3 >= arr_size){
				yyerror("Array index out of bounds.");
				$$ = null;
			}
			else{
				ret = (symbol *)malloc(sizeof(symbol));
				ret->name = (char *)NULL;	//flag for deallocate;
				ret->type = type;
				if(type==0)
					ret->value.iptr = &temp->value.iptr[$<ival>3];
				else
					ret->value.fptr = &temp->value.fptr[$<ival>3];
				ret->sym = var;
				$$ = ret;
			}
		}
	}
	;

print_statement:
	KW_PRINT									{ print_stack(); }
	| KW_PRINT DL_LPAREN expression DL_RPAREN	{
		if($<ival>3)
			printf("%d\n", $<ival>3);
	} 
	;

procedure_statement:
	ID DL_LPAREN actual_parameter_expression DL_RPAREN
	;

if_statement:
	KW_IF expression DL_COLON statement elif_statement
	| KW_IF expression DL_COLON statement elif_statement KW_ELSE DL_COLON statement
	;

elif_statement:
	%empty
	| elif_statement KW_ELIF expression DL_COLON statement
	;

while_statement:
	KW_WHILE expression DL_COLON statement
	| KW_WHILE expression DL_COLON statement KW_ELSE DL_COLON statement
	;

for_statement:
	KW_FOR for_expression KW_IN for_expression DL_COLON statement KW_ELSE DL_COLON statement
	| KW_FOR for_expression KW_IN for_expression DL_COLON statement 
	;

for_expression:
	simple_expression
	;

actual_parameter_expression:
	%empty
	| expression_list
	;

expression_list:
	expression
	| expression DL_COMMA expression_list
	;

expression:
	simple_expression
	| simple_expression relop simple_expression
	;

simple_expression:
	term
	| term addop simple_expression
	;

term:
	factor
	| factor multop term
	;

factor:
	INTEGER					{
		symbol *ret = (symbol *)malloc(sizeof(symbol));
		ret->name = (char *)NULL;	//flag for deallocation.
		ret->type = 0;
		ret->value.ival = $1;
		ret->sym = var;
		$$ = ret;
	}
	| FLOAT					{
		symbol *ret = (symbol *)malloc(sizeof(symbol));
		ret->name = (char *)NULL;	//flag for deallocation.
		ret->type = 1;
		ret->value.fval = $1;
		ret->sym = var;
		$$ = ret;
	}
	| variable				{ $$ = $1; }
	| procedure_statement	{}
	| OP_NEG factor			{}
	| sign factor			{}
	;

sign:
	OP_ADD
	| OP_SUB
	;

relop:
	OP_GT
	| OP_GE
	| OP_LT
	| OP_LE
	| OP_EQUAL
	| OP_NOTEQ
	| KW_IN
	;

addop:
	OP_ADD
	| OP_SUB
	;

multop:
	OP_MUL
	| OP_DIV
	;


%%

int main(int argc, char *argv[]){
	if (argc < 2){
		fprintf(stderr, "파일이름을 입력해야 합니다.\n");
		exit(1);
	}else if ((yyin = fopen(argv[1], "r")) != NULL){
		printf ("파일열림\n");
		init_stack();
		yyparse();
		fclose(yyin);
		printf("프로그램 종료\n");

	}else{
		fprintf(stderr, "%s 파일을 찾을 수 없습니다.\n", argv[1]);
		exit(1);
	}
	return 0;
}

void yyerror(char const *s){
	extern char* yytext;
	fprintf(stderr, "error in line %d: %s before %s\n", yylineno, s, yytext);
}
