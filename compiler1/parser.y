/*****
* Yacc parser for simple example (right recursive version)
*
* The grammar in this example is:
* all -> phrases
* phrases -> <empty>
* phrases -> NUMBER PLUS NUMBER phrases
* phrases -> NUMBER phrases
* phrases -> STRING phrases
* 
* The tokens that come from the scanner are: NUMBER, PLUS, and STRING. 
* The scanner skips all whitespace (space, tab, newline, and carriage return).
* The lexemes of the token NUMBER are strings of digits ('0'-'9'). 
* The lexeme of PLUS is only a string consisting of the plus symbol ('+').
* The lexemes of the token STRING are strings of characters that do not 
* include whitespace, digits, or the plus symbol.
* 
* Given the input "acb 42 +34 52this is", the scanner would produce 
* the tokens(/lexemes) of:
* <STRING,"abc">, <NUMBER,"42">, <PLUS,"+">, <NUMBER,"34">, <NUMBER,"52">,
* <STRING,"this">, <STRING,"is">
* 
* and this would match the grammar.
*
* This example also shows building up and returning a string
* through all the parsing rules, and then printing out when
* the grammar is done matching the input. This is VERY similar
* to how we will initially build up assembly code!
*****/

/****** Header definitions ******/
%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// function prototypes from lex
int yyerror(char *s);
int yylex(void);
int debug=0; // set to 1 to turn on extra printing

/* Not used in this code, but this can be used in Compiler 1
   to save the constant strings that need output in the 
   data section of the assembly output */
char* savedStrings[100];
int lastStringIndex=0;

%}

/* token value data types */
%union { int ival; char* str; }

/* Starting non-terminal */
%start wholeprogram
%type <str> program statements statement funcall

/* Token types */
%token <ival> LPAREN RPAREN LBRACE RBRACE SEMICOLON NUMBER PLUS KWPROGRAM KWCALL
%token <str> STRING ID

%%
/******* Rules *******/

wholeprogram: program 
     {
         printf("--- begin official output ---\n");
	 printf("#\n# RISC-V assembly output\n#\n\t.data\n\n");


         printf(".SC0:\n");
         for (int i = 0; i < lastStringIndex; i++) {
	     printf("\t.string %s\n", savedStrings[i]);
	 }
	 printf("\n\t.text\n");

         printf("#\n# main program instructions\n#\nprogram:\n");
         printf("\tla\ta0, .SC0\n");
	 printf("\tjal\tprintStr\n");

         printf("\tli a0, 0\n\tli a7, 93\n\tecall\n\n");
	 printf("#\n# some library functions\n#\n");
	 printf("# Print a null-terminated string: arg: a0 == string address\nprintStr:\n\tli a7, 4\n\tecall\n\tret\n");

     };
     
program: KWPROGRAM LBRACE statements RBRACE
     {
          if (debug) printf("yacc: %d\n", $1);
       	  $$ = (char*) malloc(30);
       	  sprintf($$, "program|%d", $1);
     };

statements: /*empty*/
       { $$ = strdup("empty"); }
     | statement statements
       {
       	  if (debug) printf("yacc: %s\n", $1);
       	  $$ = (char*) malloc(strlen($1)+12);
       	  sprintf($$, "statement|%s", $1);
       };
       
statement: funcall
       {
          if (debug) printf("yacc: %s\n", $1);
          $$ = (char*) malloc(strlen($1)+8);
          sprintf($$, "funcall|%s", $1);
       };
       
funcall: KWCALL ID LPAREN STRING RPAREN SEMICOLON
       {
       	  if (debug) printf("yacc: %d\t%s\t%d\t%s\t%d\t%d\n", $1, $2, $3, $4, $5, $6);
	  $$ = (char*) malloc(strlen($4)+8);
	  sprintf($$, "str|%s", $4);
	  savedStrings[lastStringIndex++] = $4;
       };
%%
/******* Functions *******/
extern FILE *yyin; // from lex

int main(int argc, char **argv)
{
   if (argc==2) {
      yyin = fopen(argv[1],"r");
      if (!yyin) {
         printf("Error: unable to open file (%s)\n",argv[1]);
         return(1);
      }
   }
   return(yyparse());
}

extern int yylineno; // from lex

int yyerror(char *s)
{
   fprintf(stderr, "Error: line %d: %s\n",yylineno,s);
   return 0;
}

int yywrap()
{
   return(1);
}

