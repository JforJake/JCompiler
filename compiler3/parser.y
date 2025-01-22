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
#include "symtable.c"
// function prototypes from lex
int addString(char *str);
void outputDataSection();
int functionNum = 1;
int argRegNum = 0;
int scopeLevel = 0;
int yyerror(char *s);
int yylex(void);
int debug = 0; // set to 1 to turn on extra printing
Symbol** table;

%}

/* token value data types */
%union { int ival; char* str; }

/* Starting non-terminal */
%start wholeprogram
%type <str> program functions function statements statement funcall arguments argument expression globals vardecl parameters paramdecl assignment

/* Token types */
%token <ival> LPAREN RPAREN LBRACE RBRACE SEMICOLON PLUS KWPROGRAM KWCALL KWFUNCTION COMMA NUMBER EQUALS KWGLOBAL KWINT KWSTRING
%token <str> STRING ID

%%
/******* Rules *******/

wholeprogram: globals functions program
     {
         if (debug) fprintf(stderr,"wholeprogram rule\n");
         printf("#\n# RISC-V assembly output\n#\n\n");
         outputDataSection();
         // iterate through table, do this to declare variables in assembly code
         Symbol* symbol;
         SymbolTableIter iterator;
         iterator.index = -1;
         while ((symbol=iterSymbolTable(table,0,&iterator)) != NULL) {
            printf("%s:\t.word\t0\n",symbol->name);
         }
         printf("#\n# Program instructions\n#\n\t.text\nprogram:\n%s",$3);
         printf("\tli\ta0, 0\n\tli\ta7, 93\n\tecall\n\n");
         printf("#\n# Functions\n#\n\n%s\n",$2);
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

function: KWFUNCTION ID LPAREN parameters RPAREN LBRACE statements RBRACE
       {
           scopeLevel++;
           if (debug) printf("function rule\n");
           char *code = (char*) malloc(strlen($7)+128);
           sprintf(code, "%s:\n\taddi\tsp, sp, -4\n\tsw\tra, 0(sp)\n", $2);
           strcat(code, $7);
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
       }
      | assignment
       {
           if (debug) printf("statement assignment rule\n");
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
       
assignment: ID EQUALS expression SEMICOLON
       {
           if (debug) printf("assignment rule\n");
           Symbol* symbol = findSymbol(table, $1);
           //printf("Fully ran findSymbol()\n");
           if (!symbol) {
              printf("Error: Symbol %s couldn't be found\n", $1);
              exit(1);
           }
           char* code = (char*) malloc(strlen($3) + strlen(symbol->name) + 64);
           sprintf(code, "%s\tsw\tt0, %s, t1\n", $3, symbol->name);
           $$ = code;
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
       }
     | ID
       {
           if (debug) printf("expression ID rule\n");
           char* code = (char*) malloc(sizeof($1) + 32);
           sprintf(code, "\tlw\tt0, %s\n", $1);
           $$ = code;
       };

globals: /* empty */
       { $$ = strdup(""); }
     | KWGLOBAL vardecl SEMICOLON globals
       {
           if (debug) printf("globals rule\n");
           $$ = strdup("");
       };

vardecl: KWINT ID
       {
           if (debug) printf("int declaration rule\n");
           if (addSymbol(table, $2, scopeLevel, T_INT, 10, 0) != 0) {
             printf("Error adding symbol to table: %s\n", $2);
           }
           $$ = strdup("");
       }
     | KWSTRING ID
       {
           if (debug) printf("string declaration rule\n");
           if (addSymbol(table, $2, scopeLevel, T_STRING, 10, 0) != 0) {
             printf("Error adding symbol to table: %s\n", $2);
           }
           $$ = strdup("");
       };

parameters: /* empty */
       { $$ = strdup(""); }
     | paramdecl
       {
           if (debug) printf("parameters paramdecl rule\n");
           // code for rule
           //
           //
           $$ = strdup("");
       }
     | paramdecl COMMA parameters
       {
           if (debug) printf("parameters declaration comma parameters rule\n");
           // code for rule
           //
           //
           $$ = strdup("");
       };

paramdecl: KWINT ID
       {
           if (debug) printf("int parameter declaration\n");
           $$ = strdup("");
       }
     | KWSTRING ID
       {
           if (debug) printf("string parameter declaration\n");
           $$ = strdup("");
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
   table = newSymbolTable();
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

