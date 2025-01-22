/****** Header definitions ******/
%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"
#include "astree.h"
// function prototypes from lex
int addString(char *str);
void outputDataSection();
int functionNum = 1;
int argRegNum = 0;
int scopeLevel = 0;
int yyerror(char *s);
int yylex(void);
int doAssembly;
int debug = 0; // set to 1 to turn on extra printing
Symbol** table;
ASTNode* tree;
FILE *outputFile;

%}

/* token value data types */
%union { int ival; char* str; struct astnode_s * treeNode; }

/* Starting non-terminal */
%start wholeprogram
%type <treeNode> program functions function statements statement funcall arguments argument expression globals vardecl parameters paramdecl assignment

/* Token types */
%token <ival> LPAREN RPAREN LBRACE RBRACE SEMICOLON PLUS KWPROGRAM KWCALL KWFUNCTION COMMA NUMBER EQUALS KWGLOBAL KWINT KWSTRING
%token <str> STRING ID

%%
/******* Rules *******/

wholeprogram: globals functions program
     {
         tree = newASTNode(AST_PROGRAM);
         tree->child[0] = $1;
         tree->child[1] = $2;
         tree->child[2] = $3;
         if (tree->child[2] != 0) {
          doAssembly = 1;
         } else {
          fprintf(stderr, "No main function found! Try using keyword program.");
         }
     };
     
program: KWPROGRAM LBRACE statements RBRACE
     {
          if (debug) fprintf(stderr, "program rule\n");
          $$ = $3;
     };

functions: /*empty*/ 
       { $$ = 0; }
      | function functions
       {
           if (debug) fprintf(stderr, "functions rule\n");
           $1->next = $2;
           $$ = $1;
       };

function: KWFUNCTION ID LPAREN parameters RPAREN LBRACE statements RBRACE
       {
           if (debug) fprintf(stderr, "function rule\n");
           $$ = newASTNode(AST_FUNCTION);
           $$->strval = $2;
           $$->strNeedsFreed = 1;
           $$->child[0] = $4;
           $$->child[1] = $7;
       };

statements: /*empty*/
       { $$ = 0; }
     | statement statements
       {
           $$ = $1;
           $$->next = $2;
       };
       
statement: funcall
       {   
           if (debug) fprintf(stderr, "statement rule\n");
           $$ = $1;
       }
      | assignment
       {
           if (debug) fprintf(stderr, "statement assignment rule\n");
           $$ = $1;
       };
       
funcall: KWCALL ID LPAREN arguments RPAREN SEMICOLON
       {
           if (debug) fprintf(stderr, "function call rule\n");
           $$ = newASTNode(AST_FUNCALL);
           $$->strval = $2;
           $$->strNeedsFreed = 1;
           $$->child[0] = $4;
       };
       
assignment: ID EQUALS expression SEMICOLON
       {
           if (debug) fprintf(stderr, "assignment rule\n");
           Symbol* symbol = findSymbol(table, $1);
           if (!symbol) {
              printf("Error: Symbol %s couldn't be found\n", $1);
              exit(1);
           }
           $$ = newASTNode(AST_ASSIGNMENT);
           $$->strval = symbol->name;
           $$->child[0] = $3;
           free($1);
       };

arguments: /* empty */
       { $$ = 0; }
     | argument COMMA arguments
       {
           if (debug) fprintf(stderr, "arguments rule 2\n");
           $$ = $1;
           $$->next = $3;
       }
     | argument
       {
           if (debug) fprintf(stderr, "arguments rule 1\n");
           $$ = $1;
       };

argument: expression
       {
           if (debug) fprintf(stderr, "expression rule 2\n");
           $$ = newASTNode(AST_ARGUMENT);
           $$->child[0] = $1;
       };

expression: NUMBER
       {
           if (debug) fprintf(stderr, "expression rule 1\n");
           $$ = newASTNode(AST_CONSTANT);
           $$->ival = $1;
           $$->valType = T_INT;
       }
     | STRING
       {
           if (debug) fprintf(stderr, "argument rule 1\n");
           int sid = addString($1);
           $$ = newASTNode(AST_CONSTANT);
           $$->valType = T_STRING;
           $$->strval = $1;
           $$->strNeedsFreed = 1;
           $$->ival = sid;
       }
     | ID
       {
           if (debug) fprintf(stderr, "expression ID rule\n");
           $$ = newASTNode(AST_VARREF);
           $$->strval = $1;
           $$->strNeedsFreed = 1;
       }
     | expression PLUS expression
       {
           if (debug) fprintf(stderr, "argument rule 2\n");
           $$ = newASTNode(AST_EXPRESSION);
           $$->child[0] = $1;
           $$->child[1] = $3;
       };

globals: /* empty */
       { $$ = 0; }
     | KWGLOBAL vardecl SEMICOLON globals
       {
           if (debug) fprintf(stderr, "globals rule\n");
           $$ = $2;
           $$->next = $4;
           $$->varKind = V_GLOBAL;
       };

vardecl: KWINT ID
       {
           $$ = newASTNode(AST_VARDECL);
           $$->valType = T_INT;
           $$->strval = $2;
           $$->strNeedsFreed = 1;
           
           if (debug) fprintf(stderr, "int declaration rule\n");
           if (addSymbol(table, $2, scopeLevel, T_INT, 10, 0) != 0) {
             printf("Error adding symbol to table: %s\n", $2);
           }
       }
     | KWSTRING ID
       {
           $$ = newASTNode(AST_VARDECL);
           $$->valType = T_STRING;
           $$->strval = $2;

           if (debug) fprintf(stderr, "string declaration rule\n");
           if (addSymbol(table, $2, scopeLevel, T_STRING, 10, 0) != 0) {
             printf("Error adding symbol to table: %s\n", $2);
           }
       };

parameters: /* empty */
       { $$ = 0; }
     | paramdecl
       {
           if (debug) fprintf(stderr, "parameters paramdecl rule\n");
           // code for rule
           //
           //
           $$ = 0;
       }
     | paramdecl COMMA parameters
       {
           if (debug) fprintf(stderr, "parameters declaration comma parameters rule\n");
           // code for rule
           //
           //
           $$ = 0; 
       };

paramdecl: KWINT ID
       {
           if (debug) fprintf(stderr, "int parameter declaration\n");
           $$ = 0;
           free($2);
       }
     | KWSTRING ID
       {
           if (debug) fprintf(stderr, "string parameter declaration\n");
           $$ = 0;
           free($2);
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
   for (i = 0; i < stringCount; i++) {
      fprintf(outputFile, ".SC%d:\t.string\t%s\n",i,strings[i]);
      free(strings[i]);
   }
   fprintf(outputFile, "\n");
}

extern FILE *yyin; // from lex
extern void yylex_destroy();

int main(int argc, char **argv)
{
  char newFile[64];
  doAssembly = 0;
  int stat;
   if (argc==2) {
      yyin = fopen(argv[1],"r");
      if (!yyin) {
         printf("Error: unable to open file (%s)\n",argv[1]);
         return(1);
      }
   }

   if (argc == 2) {
     if (debug) fprintf(stderr, ".s file creation started\n");
     strcpy(newFile, argv[1]);

     char *dot = strchr(newFile, '.');
     if (dot && strcmp(dot, ".j") == 0) *dot = '\0';

     strcat(newFile, ".s");
     outputFile = fopen(newFile, "w");
     if (outputFile == NULL) {
       printf("Error: Could not create file.\n");
       fclose(yyin);
       return(1);
     }
   } else {
     yyin = stdin;
     outputFile = stdout;
   }
   table = newSymbolTable();
   stat = yyparse();
   fclose(yyin);
   if (doAssembly && !stat) genCodeFromASTree(tree, 0, outputFile);
   else printASTree(tree, 0, stderr);
   freeAllSymbols(table);
   free(table);
   freeASTree(tree);
   yylex_destroy();
   fclose(outputFile);
   return stat;
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

