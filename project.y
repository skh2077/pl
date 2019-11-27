%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	extern int yylineno;
	int yylex();
	void yyerror (char const *);

	FILE *yyin;

	struct val_node{
		char *name;
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
%type <sval> sign
%token <ival> INTEGER KW_INT KW_FLOAT
%type <ival> type standard_type
%token <fval> FLOAT
%type <val_node_ptr> identifier_list
%type <symbol_ptr>  term factor variable expression simple_expression
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
		//TODO: type implement
		struct val_node *temp_node;
		union_val null, value;
		null.iptr = NULL;
		int arr_size = $1 / 2;

		for (temp_node=$2; temp_node; temp_node = temp_node->next){
			if (arr_size > 0){
				if($1 % 2 == 0)
					value.iptr = (int *)malloc(sizeof(int) * arr_size);
				else
					value.fptr = (float *)malloc(sizeof(float) * arr_size);
			}else
				value = null;

			push(temp_node->name, $1, value, var);
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
	standard_type								{ $$ = $1; }
	| standard_type DL_LBRACK INTEGER DL_RBRACK	{ $$ = $1 + $3 * 2; }
	;

identifier_list:
	ID									{
		struct val_node *new = (struct val_node *)malloc(sizeof(struct val_node));
		new->name = $1;
		new->next = NULL;
		$$ = new;
	}
	| ID DL_COMMA identifier_list		{
		struct val_node *list, *new;
		list = $3;
		new = (struct val_node *)malloc(sizeof(struct val_node));
		new->name = $1;
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
	variable DL_ASSIGN expression	{
		if(!$1 || !$3){
			char *errmsg = "value is invalid.";
			yyerror(errmsg);
		}else if($1->type != $3->type){
			int type1 = $1->type, type3 = $3->type;
			if(type1 % 2 == type3 % 2){
				if(type1 > 1 && !$1->name){					//If $1 is array element.
					if(type3 == 0)
						*$1->value.iptr = $3->value.ival;
					else if(type3 == 1)
						*$1->value.fptr = $3->value.fval;
				}else if(type3 > 1 && !$3->name){				//If $3 is array element.
					if(type1 == 0)
						$1->value.ival = *$3->value.iptr;
					else if(type1 == 1)
						$1->value.fval = *$3->value.fptr;
				}
			}
			char *errmsg = "assigning to diffrent type.";
			yyerror(errmsg);
		}else{
					printf("dddd: %d\n", $3->type);
			$1->value = $3->value;
			if(!$3->name)
				free($3);
			if(!$1->name)
				free($1);
		}
	}
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
			char *errmsg = strcat($1, " is undefined.");
			yyerror(errmsg);
			$$ = null;
		}else if(temp->sym == var){
			$$ = temp;	
		}else{
			char *errmsg = strcat($1, " is function.");
			yyerror(errmsg);
			$$ = null;
		}
	}
	| ID DL_LBRACK expression DL_RBRACK	{
		symbol *null = NULL, *temp, *ret;
		temp = search($1);
		if(!temp){
			char *errmsg = strcat($1, " is undefined.");
			yyerror(errmsg);
			$$ = null;
		}else if(temp->sym != var){
			char * errmsg =strcat($1, " is function type.");
			yyerror(errmsg);
			$$ = null;
		}
		else if (!$3){
			yyerror("index is invalid");
			$$ = null;
		}else{
			if($3->type != 0){
				char *errmsg = "index is not integer.";
				yyerror(errmsg);
				$$ = null;
			}else{
				int arr_size = temp->type / 2;
				if(arr_size < 1){
					char *errmsg = strcat($1, " is not array.");
					yyerror(errmsg);
					$$ = null;
				}else if($3->value.ival < 0 || $3->value.ival >= arr_size){
					char *errmsg = "Array index out of bounds.";
					yyerror(errmsg);
					$$ = null;
				}else{	//If name is null and type is array, then that symbol is array element.
					ret = (symbol *)malloc(sizeof(symbol));
					ret->name = (char *)NULL;	//flag for deallocate;
					ret->type = temp->type;
					if(temp->type % 2==0)
						ret->value.iptr = &temp->value.iptr[$3->value.ival];
					else
						ret->value.fptr = &temp->value.fptr[$3->value.ival];
					ret->sym = var;
					$$ = ret;
				}
			}
			if(!$3->name)
				free($3);
		}
	}
	;

print_statement:
	KW_PRINT									{ print_stack(); }
	| KW_PRINT DL_LPAREN expression DL_RPAREN	{
		if(!$3)
			yyerror("invalid expression.");
		print_sym($3);
		printf("\n");

		if(!$3->name)
			free($3);
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
	simple_expression		{
		$$ = $1;
	}
	| simple_expression relop simple_expression
	;

simple_expression:
	term					{
		$$ = $1;
	}
	| term addop simple_expression
	;

term:
	factor					{
		$$ = $1;
	}
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
	| OP_NEG factor			{
		symbol *ret = $2 ? NULL : (symbol *)malloc(sizeof(symbol));
		$$ = ret;
	}
	| sign factor			{
		symbol *ret, *null = NULL;
		if(!$2){
			char * errmsg = "variable is undefined.";
			yyerror(errmsg);
			$$ = null;
			break;
		}else if($2->sym != var){
			char *errmsg = "invalid type 'function' to unary expression.";
			yyerror(errmsg);
			$$ = null;
			break;
		}else if($2->type > 1){
			char *errmsg = " is invalid type 'array' to unary expression.";
		}
		ret = (symbol *)malloc(sizeof(symbol));
		ret->name = (char *)NULL;	//flag for deallocation.
		ret->type = $2->type;
		int sign = *$1 == '-' ? -1 : 1;
		if($2->type == 0)
			ret->value.ival = $2->value.ival * sign;
		else if($2->type == 1)
			ret->value.fval = $2->value.fval * (float)sign;
		ret->sym = var;

		$$ = ret;

		if(!$2->name)
			free($2);
	}
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
