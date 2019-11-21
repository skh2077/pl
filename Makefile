defaul:
	clear
	flex project.lex
	bison project.y -dv
	gcc -o project project.tab.c lex.yy.c -lfl
