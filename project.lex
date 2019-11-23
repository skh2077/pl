%{
#include "project.tab.h"
%}

%option yylineno
%option noyywrap
DIGIT	[0-9]
LETTER	[a-zA-Z]

%%
[\n]												;										
[\t ]+												;
mainprog											{ return KW_MAIN;			}
function											{ return KW_FUNC;			}
procedure											{ return KW_PROC;			}
begin													{ return KW_BEGIN;		}
end														{ return KW_END;			}
int														{ return KW_INT;			}
float													{ return KW_FLOAT;		}
if														{ return KW_IF;				}
then													{ return KW_THEN;			}
else													{ return KW_ELSE;			}
elif													{ return KW_ELIF;			}
nop														{ return KW_NOP;			}
for														{ return KW_FOR;			}
while													{ return KW_WHILE;		}
return												{ return KW_RETURN;		}
print													{ return KW_PRINT;		}
in														{ return KW_IN;				}
{DIGIT}+											{ return INTEGER;			}
{DIGIT}+"."{DIGIT}+						{ return FLOAT;				}
{LETTER}({LETTER}|{DIGIT})*		{ return ID;					}
"+"														{ return OP_ADD;			}
"-"														{ return OP_SUB;			}
"*"														{ return OP_MUL;			}
"/"														{ return OP_DIV;			}
"<"														{ return OP_LT;				}
"<="													{ return OP_LE;				}
">="													{ return OP_GE;				}
">"														{ return OP_GT;				}
"=="													{ return OP_EQUAL;		}
"!="													{ return OP_NOTEQ;		}
"!"														{ return OP_NEG;			}
";"														{ return DL_SMCOLON;	}
"."														{ return DL_DOT;			}
","														{ return DL_COMMA;		}
"="														{ return DL_ASSIGN;		}
"("														{ return DL_LPAREN;		}
")"														{ return DL_RPAREN;		}
"["														{ return DL_LBRACK;		}
"]"														{ return DL_RBRACK;		}
":"														{ return DL_COLON;		}
[\/\/].*
.															{ return yytext[0];		}
%%
