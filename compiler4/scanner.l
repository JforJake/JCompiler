/****
* Lex scanner for simple example
* - see the header comments in parser.y for more 
*   explanation of what this scanner does
****/

/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// The ifndef below allows this scanner definition to be
// used either with a yacc generated parser or all by
// itself (if LEXONLY is defined)
#ifndef LEXONLY
// definitions are auto-created by yacc so just include them
#include "y.tab.h"
extern int debug; // declared and set in parser.y
#else
// we must have explicit definitions for standalone mode
typedef union { int ival; char* str; } yystype;
#define YYSTYPE yystype
yystype yylval;
#define NUMBER     1
#define PLUS       2
#define STRING     3
#define LBRACE     4
#define LPAREN     5
#define KWPROGRAM  6
#define RBRACE     7
#define RPAREN     8
#define SEMICOLON  9
#define KWCALL     10
#define ID         11
#define KWFUNCTION 12
#define COMMA      13
#define EQUALS     14
#define KWINT      15
#define KWSTRING   16
#define KWGLOBAL   17

int debug = 0;
#endif
%}

/* This option is useful for printing out a syntax error
*  message and printing out the line # it occurred on
*/
%option yylineno

/****** Token Patterns ******/
%%
[ \t\n\r]+ { /* skipping white space */ }

function {
           if (debug) printf("lex: function\n");
           yylval.ival = yytext[0];
           return(KWFUNCTION);
         }
         
program	{
      	  if (debug) printf("lex: KWPROGRAM\n");
           yylval.ival = yytext[0];
           return(KWPROGRAM);
	      }
	 
call	   {
	         if (debug) printf("lex: KWCALL\n");
            yylval.ival = yytext[0];
            return(KWCALL);
	      }

int      {
            if (debug) printf("lex: KWINT\n");
            yylval.ival = yytext[0];
            return(KWINT);
         }

string   {
            if (debug) printf("lex: KWSTRING\n");
            yylval.ival = yytext[0];
            return(KWSTRING);
         }

global   {
            if (debug) printf("lex: KWGLOBAL\n");
            yylval.ival = yytext[0];
            return(KWGLOBAL);
         }
         
\+       {
            if (debug) printf("lex: plus symbol\n");
            yylval.ival = yytext[0];
            return(PLUS);
         }

\,       {
            if (debug) printf("lex: comma symbol\n");
            yylval.ival = yytext[0];
            return(COMMA);
         }
         
\{	      {
	        if (debug) printf("lex: left brace symbol\n");
           yylval.ival = yytext[0];
           return(LBRACE);
	      }         
	
\(	      {
	         if (debug) printf("lex: left parenthesis symbol\n");
            yylval.ival = yytext[0];
            return(LPAREN);
	      }
	
\}	      {
	         if (debug) printf("lex: right brace symbol\n");
            yylval.ival = yytext[0];
            return(RBRACE);
	      }
	
\)	      {
	         if (debug) printf("lex: right parenthesis symbol\n");
            yylval.ival = yytext[0];
            return(RPAREN);
	      }
	
\;	      {
	         if (debug) printf("lex: semicolon symbol\n");
            yylval.ival = yytext[0];
            return(SEMICOLON);
	      }

\=       {
            if (debug) printf("lex: equals symbol\n");
            yylval.ival = yytext[0];
            return(EQUALS);
         }

[a-zA-Z_][a-zA-Z0-9_]* {
	         if (debug) printf("lex: ID\n");
            yylval.str = strdup(yytext);
            return(ID);
	      }

\"[^\"]+\"  {
            if (debug) printf("lex: string (%s)\n", yytext);
            yylval.str = strdup(yytext);
            return(STRING);
         }

[0-9]+   {
            if (debug) printf("lex: number (%s)\n", yytext);
            yylval.ival = strtol(yytext,NULL,10);
            return(NUMBER);
         }
%%




/****** Functions (not used when used with parser) *******/

//
// Code in the ifdef block below is only for compiling the
// scanner all by itself, for testing purposes. The 
// Makefile shows how to compile it under the "ltest" rule
// (do "make ltest" to build it)
//
#ifdef LEXONLY

// A main for standalone testing (uses just stdin as input)
int main(int argc, char **argv) 
{
   do {
      yylex();
   } while (1);
   // while (!feof(stdin)); doesn't work if redirecting a file
   // in because the file is read in and buffered, and eof is
   // true too early, causing lex to stop; rather, use while(1)
   // and then do a hard exit in yywrap(); ugly, but works!
   return 0;
}

int yywrap()
{
   exit(0); // hard exit!
   //return(1);
}

#endif // LEXONLY


