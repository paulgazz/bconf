%{
#include <stdio.h>
#include <string.h>

extern char *filename;
extern int bconflineno;

extern int bconflex(void);
static void bconf_error(const char *err, ...);

%}

%union
{
  char *string;
  int num;
}

/* bash reserved words */
%token IF THEN ELSE ELIF FI

/* bconf reserved words */
%token MAINMENU_OPTION
%token MAINMENU_NAME
%token ENDMENU
%token HELP
%token READLN
%token COMMENT
%token DEFINE_BOOL
%token DEFINE_TRISTATE
%token BOOL
%token TRISTATE
%token DEP_TRISTATE
%token DEP_BOOL
%token DEP_MBOOL
%token DEFINE_INT
%token INT
%token DEFINE_HEX
%token HEX
%token DEFINE_STRING
%token STRING
%token CHOICE

/* bconf values */
%token <string> CONFIG_VAR WORD NUMBER

/* bconf literals */
%token <string> STRING_CONST TRISTATE_CONST

/* bconf conditional expressions */
%token TEST_STREQ TEST_STRNE TEST_N TEST_Z TEST_EQ TEST_NE TEST_GE TEST_GT
%token TEST_LE TEST_LT TEST_AND TEST_OR TEST_BANG

/* bash built-ins */
%token UNSET

/* bash statements appear on one line at a time, or followed by a semicolon */
%token NEWLINE

%type <string> tristate_value

%%

inputunit:
    /* empty */
  | statement_list ;

statement_list:
    statement
  | statement_list statement ;

statement:
    /* empty statement */ NEWLINE
  | MAINMENU_OPTION WORD NEWLINE
  | MAINMENU_NAME   STRING_CONST NEWLINE
  | ENDMENU         NEWLINE
  | COMMENT         STRING_CONST NEWLINE
  | DEFINE_BOOL     WORD tristate_value NEWLINE
  | DEFINE_TRISTATE WORD tristate_value NEWLINE
  | BOOL            STRING_CONST WORD tristate_const_opt NEWLINE
  | TRISTATE        STRING_CONST WORD config_var_opt NEWLINE
  | DEP_TRISTATE    STRING_CONST WORD dep_list NEWLINE
  | DEP_BOOL        STRING_CONST WORD dep_list NEWLINE
  | DEP_MBOOL       STRING_CONST WORD dep_list NEWLINE
  | DEFINE_INT      WORD NUMBER NEWLINE
  | INT             STRING_CONST WORD NUMBER min_max_opt NEWLINE
  | DEFINE_HEX      WORD NUMBER NEWLINE
  | HEX             STRING_CONST WORD NUMBER NEWLINE
  | DEFINE_STRING
  | STRING          STRING_CONST WORD STRING_CONST NEWLINE
  | STRING          STRING_CONST WORD WORD NEWLINE
  | CHOICE          STRING_CONST STRING_CONST WORD NEWLINE
  | UNSET           WORD NEWLINE /* do nothing */
  | if_block
  ;

tristate_value:
    TRISTATE_CONST { $$ = $1; }
  | CONFIG_VAR { $$ = $1; }
  ;

tristate_const_opt:
    /* empty */
  | TRISTATE_CONST ;

config_var_opt:
    /* empty */
  | CONFIG_VAR ;

dep_list:
    CONFIG_VAR
  | TRISTATE_CONST
  | dep_list CONFIG_VAR
  | dep_list TRISTATE_CONST ;

min_max_opt:
    /* empty */
  | NUMBER
  | NUMBER NUMBER
  ;

if_block: IF conditional_expression NEWLINE THEN statement_list elif_opt else_opt FI NEWLINE ;

elif_opt:
    /* empty */
  | elif_opt elif_branch
  ;

elif_branch: ELIF conditional_expression NEWLINE THEN statement_list ;

else_opt:
    /* empty */
  | ELSE statement_list ;

conditional_expression:
    term
  | conditional_expression TEST_OR term
  ;

term:
    factor
  | term TEST_AND factor
  ;

factor:
    id
  | TEST_BANG factor
  | id TEST_STREQ id
  | id TEST_STRNE id
  | TEST_N id
  | TEST_Z id
  | NUMBER TEST_EQ NUMBER
  | NUMBER TEST_NE NUMBER
  | NUMBER TEST_GE NUMBER
  | NUMBER TEST_GT NUMBER
  | NUMBER TEST_LE NUMBER
  | NUMBER TEST_LT NUMBER
  ;

id: CONFIG_VAR | TRISTATE_CONST | STRING_CONST | NUMBER ;

%%

#include "bconf.lex.c"

char *filename;

bconf_test_lexer(char *file)
{
  int t;

  bconfin = fopen(file, "r");
  filename = file;
  bconflineno = 1;
  while (t = bconflex()) {
    printf("%s: %s\n", yytname[t - 255], bconftext);
  }
}

bconferror(char *msg) {
  fprintf(stderr, "error:%s:%d: %s\n", filename, bconflineno, msg);
  exit(1);
}

main(int argc, char **argv)
{
  char *file;

  if (argc == 1) {
    printf("USAGE: %s arch/i386/config.in", argv[0]);
    exit(0);
  }

  file = argv[1];

  bconf_test_lexer(file);

  return 0;
}
