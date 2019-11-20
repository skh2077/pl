bison example.y -d
flex example.lex
gcc -o result example.tab.c lex.yy.c -ll
