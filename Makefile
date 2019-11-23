CC		= gcc
LIBS	= -ll
LEX		= flex
YACC	= bison
TARGET	= project

all: $(TARGET)

project.tab.c project.tab.h:	project.y 
	$(YACC) project.y -dv

lex.yy.c:	project.lex project.tab.h
	$(LEX) project.lex

$(TARGET):	lex.yy.c project.tab.c project.tab.h
	$(CC) -o $(TARGET) project.tab.c lex.yy.c $(LIBS)
