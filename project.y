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
		union_val null;
		null.iptr = NULL;
		int type = 
		for (temp_node=$2; temp_node; temp_node = temp_node->next){
			
			push(temp_node->name, $1, null, var);
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
		}else if(temp->sym == var){
			if(temp->type==0 || temp->type==1){
				$$ = temp;
			}else{
				char *errmsg = strcat($1, " is array.");
				yyerror(errmsg);
				$$ = null;
			}
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
			char *errmsg = strcat($1, " is not defined.");
			yyerror(errmsg);
			$$ = null;
		}else if(temp->sym != var){
			char * errmsg =strcat($1, " is function type.");
			yyerror(errmsg);
			$$ = null;
		}
		else if($3->type != 0){
			char *errmsg = "index is not integer.";
			yyerror(errmsg);
			$$ = null;
		}else{
			int type = temp->type % 2, arr_size = temp->type / 2;
			if(arr_size < 1){
				char *errmsg = strcat($1, " is not array.");
				yyerror(errmsg);
				$$ = null;
			}else if($3->value.ival < 0 || $3->value.ival >= arr_size){
				char *errmsg = "Array index out of bounds.";
				yyerror(errmsg);
				$$ = null;
			}else{
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
		if(!$3){
			yyerror("unvalid expresson.");
			break;
		}
		switch($3->sym){
			case var:
				if($3->type < 0){
					char *print_str;
					print_str = $3->value.ival == 0 ? "false" : "true";
					printf("%s\n", print_str);
				}else if($3->type > 1){
					if($3->type % 2 == 0)
						printf("%d\n", *$3->value.iptr);
					else
						printf("%f\n", *$3->value.fptr);
				}else{
					if($3->type % 2 == 0)
						printf("%d\n", $3->value.ival);
					else
						printf("%f\n", $3->value.fval);
				}
				if(!$3->name)
					free($3);
				break;
			default:
				printf("function\n");
				break;
		}

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
	| OP_NEG factor			{
		symbol *ret = $2 ? NULL : (symbol *)malloc(sizeof(symbol));
		$$ = ret;
	}
	| sign factor			{
		symbol *ret, *null = NULL;
		if(!$2){
			char * errmsg = "variable is not defined.";
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
