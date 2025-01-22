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
int addString(char *str);
void outputDataSection();
int functionNum=1;
int argRegNum = 0;
int yyerror(char *s);
int yylex(void);
int debug=0; // set to 1 to turn on extra printing

/* Not used in this code, but this can be used in Compiler 1
   to save the constant strings that need output in the 
   data section of the assembly output */

%}

/* token value data types */
%union { int ival; char* str; }

/* Starting non-terminal */
%start wholeprogram
%type <str> program functions function statements statement funcall arguments argument expression

/* Token types */
%token <ival> LPAREN RPAREN LBRACE RBRACE SEMICOLON PLUS KWPROGRAM KWCALL KWFUNCTION COMMA NUMBER
%token <str> STRING ID

%%
/******* Rules *******/

wholeprogram: functions program
     {
         if (debug) fprintf(stderr,"wholeprogram rule\n");
         printf("#\n# RISC-V assembly output\n#\n\n");
         outputDataSection();
         printf("#\n# Program instructions\n#\n\t.text\nprogram:\n%s",$2);
         printf("\tli\ta0, 0\n\tli\ta7, 93\n\tecall\n\n");
         printf("#\n# Functions\n#\n\n%s\n",$1);
         printf("#\n# Library functions\n#\n\n");
         printf("# Print a null-terminated string: arg: a0 == string address\nprintStr:\n\tli\ta7, 4\n\tecall\n\tret\n\n");
         printf("# Print a decimal integer: arg: a0 == value\nprintInt:\n\tli\ta7, 1\n\tecall\n\tret\n\n");
     };
     
program: KWPROGRAM LBRACE statements RBRACE
     {
          if (debug) printf("program rule\n");
       	  $$ = $3;
     };

functions: /*empty*/ 
       { $$ = strdup(""); }
      | function functions
       {
           if (debug) printf("functions rule\n");
           char *code = (char*) malloc(strlen($1)+strlen($2)+5);
           strcpy(code, $1);
           strcat(code, $2);
           $$ = code;
           free($1);
           free($2);
       };

function: KWFUNCTION ID LPAREN RPAREN LBRACE statements RBRACE
       {
           if (debug) printf("function rule\n");
           char *code = (char*) malloc(strlen($6)+128);
           sprintf(code, "%s:\n\taddi\tsp, sp, -4\n\tsw\tra, 0(sp)\n", $2);
           strcat(code, $6);
           strcat(code, "\tlw\tra, 0(sp)\n\taddi\tsp, sp, 4\n\tret\n\n");
           $$ = code;
       };

statements: /*empty*/
       { $$ = strdup(""); }
     | statement statements
       {
       	  if (debug) printf("statements rule\n");
           char *code = (char*) malloc(strlen($1)+strlen($2)+5);
           strcpy(code, $1);
           strcat(code, $2);
           $$ = code;
           free($1);
           free($2);
       };
       
statement: funcall
       {
           if (debug) printf("statement rule\n");
           $$ = $1;
       };
       
funcall: KWCALL ID LPAREN arguments RPAREN SEMICOLON
       {
       	   if (debug) printf("function call rule\n");
           char* code = (char*) malloc(strlen($4)+strlen($2)+32);
	       sprintf(code, "%s\tjal\t%s\n", $4, $2);
	       $$ = code;
           argRegNum = 0;
       };

arguments: /* empty */
       { $$ = strdup(""); }
     | argument
       {
           if (debug) printf("arguments rule 1\n");
           $$ = $1;
       }
     | argument COMMA arguments
       {
           if (debug) printf("arguments rule 2\n");
           char* code = (char*) malloc(strlen($1)+strlen($3)+5);
           strcpy(code, $1);
           strcat(code, $3);
           $$ = code;
           free($1);
           free($3);
       };

argument: STRING
       {
           if (debug) printf("argument rule 1\n");
           int sid = addString($1);
           char *code = (char*) malloc(32);
           sprintf(code, "\tla\ta%d, .SC%d\n", argRegNum, sid);
           $$ = code;
           argRegNum++;
       }
     | expression
       {
           if (debug) printf("argument rule 2\n");
           char *code = (char*) malloc(strlen($1)+32);
           sprintf(code, "%s\tmv\ta%d, t0\n", $1, argRegNum);
           $$ = code;
           argRegNum++;
       };

expression: NUMBER
       {
           if (debug) printf("expression rule 1\n");
           char* code = (char*) malloc(32);
           sprintf(code, "\tli\tt0, %d\n", $1);
           $$ = code;
       }
     | expression PLUS expression
       {
           if (debug) printf("expression rule 2\n");
           char* code = (char*) malloc(strlen($1)+strlen($3)+128);
           strcpy(code, $1);
           strcat(code, "\taddi\tsp, sp, -4\n\tsw\tt0, 0(sp)\n");
           strcat(code, $3);
           strcat(code, "\tlw\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\tadd\tt0, t0, t1\n");
           $$ = code;
           free($1);
           free($3);
       };
%%

/******* Functions *******/

int stringCount = 0;
char *strings[128];

int addString(char *str)
{
    int i = stringCount++;
    strings[i] = strdup(str);
    return(i);
}

void outputDataSection()
{
   int i;
   printf("#\n# Data section\n#\n\t.data\n");
   for (i = 0; i < stringCount; i++) {
      printf(".SC%d:\t.string\t%s\n",i,strings[i]);
   }
   printf("\n");
}

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

