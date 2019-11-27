%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>

	#define TRUE 1
	#define FALSE 0

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
	declarations type identifier_list DL_SMCOLON	{
		struct val_node *temp_node;
		union_val value;
		int arr_size = $2 / 2;

		for (temp_node=$3; temp_node; temp_node = temp_node->next){
			if(sym_stack_is_full()){
				yyerror("Variable stack is full");
				break;
			}
			if(search(temp_node->name)){
				yyerror(strcat(temp_node->name, " is already declared."));
				continue;
			}
			if (arr_size > 0){
				if($2 % 2 == 0)
					value.iptr = (int *)malloc(sizeof(int) * arr_size);
				else
					value.fptr = (float *)malloc(sizeof(float) * arr_size);
			}else{
				value = (union_val)0;
			}

			push(temp_node->name, $2, value, var);
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
		_type _type1 = _typeof($1), _type3 = _typeof($3);

		if(!_type1 || !_type3)
			yyerror("value is invalid");
		else if($1->sym != var || $3->sym != var)
			yyerror("expression is invalid");
		else if($1->type != $3->type){
			if(_type1 == _int_elem && _type3 == _int)
				*$1->value.iptr = $3->value.ival;
			else if(_type1 == _float_elem && _type3 == _float)
				*$1->value.fptr = $3->value.fval;
			else if(_type1 == _int && _type3 == _int_elem)
				$1->value.ival = *$3->value.iptr;
			else if(_type1 == _float && _type3 == _float_elem)
				$1->value.fval = *$3->value.fptr;
			else{
				char *errmsg = "assigning to diffrent type.";
				yyerror(errmsg);
			}
		}else{
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
			char *errmsg = strcat($1, " is undeclared.");
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
		symbol *null = NULL, *id, *ret;
		int arr_size, index_value;
		char *errmsg;
		id = search($1);
		_type _typeof_id = _typeof(id), _typeof_index = _typeof($3);

		switch(_typeof_id){
			case _NULL:
				errmsg = strcat($1, " is undeclared.");
				yyerror(errmsg);
				$$ = null;
				break;

			case _int_arr:
			case _float_arr:
				switch(_typeof_index){
					case _NULL:
						yyerror("Invalid value.");
						break;

					case _int:
					case _int_elem:
						arr_size = id->type / 2;
						index_value = _typeof_index == _int ? $3->value.ival : *$3->value.iptr;
							
						if(index_value < 0 || index_value >= arr_size){
							yyerror("Array index out of bounds.");
							$$ = null;
						}else{
							ret = (symbol *)malloc(sizeof(symbol));
							ret->name = (char *)NULL;	//flag for deallocate
							ret->type = id->type;
							if(_typeof_id == _int_arr)
								if(_typeof_index == _int)
									ret->value.iptr = &id->value.iptr[$3->value.ival];
								else{ // if(_typeof_index == _int_elem)
									ret->value.iptr = &id->value.iptr[*$3->value.iptr];
								}
							else // if(_typeof_id == _float_arr)
								if(_typeof_index == _int)
									ret->value.fptr = &id->value.fptr[$3->value.ival];
								else{ // if(_typeof_index == _int_elem)
									ret->value.fptr = &id->value.fptr[*$3->value.iptr];
								}
							ret->sym = var;
							$$ = ret;

							if(!$3->name)				//If index is temporary variable 
								free($3);
						}
						break;

					default:
						yyerror("Index is not integer.");
						$$ = null;
				}
				break;
			default:
				yyerror("ID is not array.");
				$$ = null;
		}
	}
	;

print_statement:
	KW_PRINT									{ print_stack(); }
	| KW_PRINT DL_LPAREN expression DL_RPAREN	{
		if(!$3)
			break;

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
	| factor multop term	{
		if(!$1 || !$3){
			yyerror("invalid term.");
			break;
		}
	}	
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
		char *errmsg;
		_type _typeof_factor = _typeof($2);

		switch(_typeof_factor){
			case _NULL:
				yyerror("Invalid value.");
				break;
			case _true:
			case _false:
				$2->type = !$2->type ? TRUE : FALSE;
				break;
			default:
				errmsg = strcat(_typeof_str($2), "' is not boolean.");
				errmsg = strcat("type '", errmsg);
				yyerror(errmsg);
		}

		free($1);		//free char *strdub()
	}
	| sign factor			{
		symbol *ret, *null = NULL;
		_type _typeof_factor = _typeof($2);
		char *errmsg;
		int sign = *$1 == '+' ? 1 : -1;
		switch(_typeof_factor){
			case _func:
			case _proc:
			case _true:
			case _false:
			case _int_arr:
			case _float_arr:
				errmsg = strcat("Invalid type '", _typeof_str($2));
				errmsg = strcat(errmsg, "' to unary expression.");
				yyerror(errmsg);
				$$ = null;
				break;
			case _int:
			case _float:
			case _int_elem:
			case _float_elem:
				ret = (symbol *)malloc(sizeof(symbol));
				ret->name = (char *)NULL;	//flag for deallocation.
				ret->type = $2->type;
				if(_typeof_factor == _int)
					ret->value.ival = $2->value.ival * sign;
				else if(_typeof_factor == _float)
					ret->value.fval = $2->value.fval * sign;
				else if(_typeof_factor == _int_elem)
					ret->value.fval = *$2->value.iptr * sign;
				else // if(_typeof_factor == _float_elem
					ret->value.fval = *$2->value.fptr * sign;
				ret->sym = var;

				$$ = ret;
				break;
			default:
				yyerror("Invalid value.");
				$$ = null;
		}

		if($2)
			if(!$2->name)
				free($2);					//free temporary variable

		free($1);							//free char *strdup()
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
	//TODO All name string of tokens should be free because of strdup().
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
