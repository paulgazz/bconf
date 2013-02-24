%option prefix="bconf"
%option noyywrap
%option yylineno

%{
#include <stdio.h>
#include <string.h>
%}

WORD [a-zA-Z_/\.][0-9a-zA-Z_/\.\-]*

FILENAME [0-9a-zA-Z_\-/\.]+

/* Tristate constants */
TRISTATE_CONST  y|n|m

/* Strings */
SIMPLE_ESCAPE   [abefnrtv\'\"?\\]
OCTAL_ESCAPE    [0-7]{1,3}
HEX_ESCAPE      "x"[0-9a-fA-F]+
ESCAPE_SEQUENCE [\\]({SIMPLE_ESCAPE}|{OCTAL_ESCAPE}|{HEX_ESCAPE})
STRING_CHAR_D   [^\"\\\n]|{ESCAPE_SEQUENCE}|{CONTINUATION}
STRING_CHAR_S   [^\'\\\n]|{ESCAPE_SEQUENCE}|{CONTINUATION}

/* Whitespace and newlines */
NEWLINE      \r|\n|\r\n
TAB          [\011]
CONTINUATION "\\\n"
WHITESPACE   ([ ]|{TAB})+|{CONTINUATION}

/* Bash-style comments */
COMMENT [^\r\n]*"#"[^\r\n]*{NEWLINE}

/* separate lexing for test conditions */
%x IN_TEST

%%

<INITIAL>{
if     return IF;
then   return THEN;
else   return ELSE;
elif   return ELIF;
fi     return FI;
unset  return UNSET;
source return SOURCE;

mainmenu_option return MAINMENU_OPTION;
mainmenu_name   return MAINMENU_NAME;
endmenu         return ENDMENU;
help            return HELP;
readln          return READLN;
comment         return COMMENT;
define_bool     return DEFINE_BOOL;
define_tristate return DEFINE_TRISTATE;
bool            return BOOL;
tristate        return TRISTATE;
dep_tristate    return DEP_TRISTATE;
dep_bool        return DEP_BOOL;
dep_mbool       return DEP_MBOOL;
define_int      return DEFINE_INT;
int             return INT;
define_hex      return DEFINE_HEX;
hex             return HEX;
define_string   return DEFINE_STRING;
string          return STRING;
choice          return CHOICE;

"[["|"]]"       { fprintf(stderr, "error:%d: \"%s\"ksh-style conditionals unsupported\n", yylineno, yytext); exit(1); }

"["             BEGIN(IN_TEST);

{TRISTATE_CONST} {
  yylval.string = strdup(yytext);
  return TRISTATE_CONST;
}

0x[0-9a-fA-F]+|[0-9a-fA-F]+ {
  yylval.string = strdup(yytext);
  return NUMBER;
}

\"({STRING_CHAR_D})*\"|\'({STRING_CHAR_S})*\' {
  yylval.string = strdup(yytext);
  return STRING_CONST;
}

${WORD} {
  yylval.string = strdup(yytext);
  return CONFIG_VAR;
}

{WORD} {
  yylval.string = strdup(yytext);
  return WORD;
}
}

<IN_TEST>{
"]"             BEGIN(INITIAL);
"="             return TEST_STREQ;
"!="            return TEST_STRNE;
"-n"            return TEST_N;
"-z"            return TEST_Z;
"-eq"           return TEST_EQ;
"-ne"           return TEST_NE;
"-ge"           return TEST_GE;
"-gt"           return TEST_GT;
"-le"           return TEST_LE;
"-lt"           return TEST_LT;
"-a"            return TEST_AND;
"-o"            return TEST_OR;
"!"             return TEST_BANG;
\"{TRISTATE_CONST}\" {
  yylval.string = strdup(yytext);
  return TRISTATE_CONST;
}
\"${WORD}\" {
  yylval.string = strdup(yytext);
  return CONFIG_VAR;
}
\"{WORD}\" {
  yylval.string = strdup(yytext);
  return STRING_CONST;
}
\"[0-9]+\" {
  yylval.string = strdup(yytext);
  return NUMBER;
}
}

<INITIAL,IN_TEST>{
{WHITESPACE}+
}

<INITIAL>{
{COMMENT}
({NEWLINE}|;)+  return NEWLINE;
. { fprintf(stderr, "lexer error:%d: %s\n", yylineno, yytext); exit(1); }
}

<IN_TEST>{
. { fprintf(stderr, "lexer error:%d: %s\n", yylineno, yytext); exit(1); }
}
