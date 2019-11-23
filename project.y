%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	extern int yylineno;
	void yyerror (char const *);
	int yylex();
	FILE *yyin;
%}

%union {
	int ival;
	float fval;
	char *sval;
}
%locations

%token <sval> ID KW_MAIN KW_FUNC KW_PROC KW_BEGIN KW_END KW_INT KW_FLOAT KW_IF KW_THEN KW_ELSE KW_ELIF KW_NOP KW_FOR KW_WHILE KW_RETURN KW_PRINT KW_IN OP_ADD OP_SUB OP_MUL OP_DIV OP_LT OP_LE OP_GT OP_GE OP_EQUAL OP_NOTEQ OP_NEG DL_SMCOLON DL_DOT DL_COMMA DL_ASSIGN DL_LPAREN DL_RPAREN DL_LBRACK DL_RBRACK DL_COLON
%token <ival> INTEGER
%token <fval> FLOAT
%precedence DL_COLON
%precedence KW_ELIF
%precedence KW_ELSE
%right KW_IN

%%

program:
	%empty
	| KW_MAIN ID DL_SMCOLON declarations subprogram_declarations compound_statement
	;

declarations:	
	type identifier_list DL_SMCOLON declarations 
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
	ID
	| ID DL_COMMA identifier_list
	;

standard_type:
	KW_INT
	| KW_FLOAT
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
	ID
	| ID DL_LBRACK expression DL_RBRACK
	;

print_statement:
	KW_PRINT
	| KW_PRINT DL_LPAREN expression DL_RPAREN 
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
	INTEGER
	| FLOAT
	| variable
	| procedure_statement
	| OP_NEG factor
	| sign factor
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
	FILE *fp;

	if (argc < 2){
		fprintf(stderr, "파일이름을 입력해야 합니다.\n");
		exit(1);
	}else if ((yyin = fopen(argv[1], "r")) != NULL){
		printf ("파일열림\n");
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
	fprintf(stderr,"Error | Line: %d\n%s\n",yylineno,s);
}
