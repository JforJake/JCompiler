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
int ldebug = 0;
#else
// we must have explicit definitions for standalone mode
typedef union { int ival; char* str; } yystype;
#define YYSTYPE yystype
yystype yylval;
#define NUMBER      1
#define ADDOP       2
#define STRING      3
#define LBRACE      4
#define LPAREN      5
#define KWPROGRAM   6
#define RBRACE      7
#define RPAREN      8
#define SEMICOLON   9
#define KWCALL      10
#define ID          11
#define KWFUNCTION  12
#define COMMA       13
#define EQUALS      14
#define KWINT       15
#define KWSTRING    16
#define KWGLOBAL    17
#define RELOP       18
#define KWRETURNVAL 19
#define KWWHILE     20
#define KWDO        21
#define KWIF        22
#define KWTHEN      23
#define KWELSE      24
#define LBRACKET    25
#define RBRACKET    26

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
           if (ldebug) printf("lex: function\n");
           yylval.ival = yytext[0];
           return(KWFUNCTION);
         }
         
program	{
      	  if (ldebug) printf("lex: KWPROGRAM\n");
           yylval.ival = yytext[0];
           return(KWPROGRAM);
	      }

returnvalue {
           if (ldebug) printf("lex: KWRETURNVAL\n");
           yylval.ival = yytext[0];
           return(KWRETURNVAL);
         }
	 
while 	{
      	  if (ldebug) printf("lex: KWWHILE\n");
           yylval.ival = yytext[0];
           return(KWWHILE);
	      }
         
do    	{
      	  if (ldebug) printf("lex: KWDO\n");
           yylval.ival = yytext[0];
           return(KWDO);
	      }

if    	{
      	  if (ldebug) printf("lex: KWIF\n");
           yylval.ival = yytext[0];
           return(KWIF);
	      }

then  	{
      	  if (ldebug) printf("lex: KWTHEN\n");
           yylval.ival = yytext[0];
           return(KWTHEN);
	      }

else  	{
      	  if (ldebug) printf("lex: KWELSE\n");
           yylval.ival = yytext[0];
           return(KWELSE);
	      }

call	   {
	         if (ldebug) printf("lex: KWCALL\n");
            yylval.ival = yytext[0];
            return(KWCALL);
	      }

int      {
            if (ldebug) printf("lex: KWINT\n");
            yylval.ival = yytext[0];
            return(KWINT);
         }

string   {
            if (ldebug) printf("lex: KWSTRING\n");
            yylval.ival = yytext[0];
            return(KWSTRING);
         }

global   {
            if (ldebug) printf("lex: KWGLOBAL\n");
            yylval.ival = yytext[0];
            return(KWGLOBAL);
         }
         
\+       {
            if (ldebug) printf("lex: plus symbol\n");
            yylval.ival = yytext[0];
            return(ADDOP);
         }

\-       {
            if (ldebug) printf("lex: minus symbol\n");
            yylval.ival = yytext[0];
            return(ADDOP);
         }

\==      {
            if (ldebug) printf("lex: equal comparison symbol\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }
         
\!=      {
            if (ldebug) printf("lex: not equal comparison symbol\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }

\>      {
            if (ldebug) printf("lex: greater than comparison symbol\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }

\<      {
            if (ldebug) printf("lex: less than comparison symbol\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }

\,       {
            if (ldebug) printf("lex: comma symbol\n");
            yylval.ival = yytext[0];
            return(COMMA);
         }
         
\{	      {
	        if (ldebug) printf("lex: left brace symbol\n");
           yylval.ival = yytext[0];
           return(LBRACE);
	      }         
	
\(	      {
	         if (ldebug) printf("lex: left parenthesis symbol\n");
            yylval.ival = yytext[0];
            return(LPAREN);
	      }

\[       {
            if (ldebug) printf("lex: left bracket symbol\b");
            yylval.ival = yytext[0];
            return(LBRACKET);
         }
	
\}	      {
	         if (ldebug) printf("lex: right brace symbol\n");
            yylval.ival = yytext[0];
            return(RBRACE);
	      }
	
\)	      {
	         if (ldebug) printf("lex: right parenthesis symbol\n");
            yylval.ival = yytext[0];
            return(RPAREN);
	      }
         
\]       {
            if (ldebug) printf("lex: right bracket symbol\b");
            yylval.ival = yytext[0];
            return(RBRACKET);
         }
	
\;	      {
	         if (ldebug) printf("lex: semicolon symbol\n");
            yylval.ival = yytext[0];
            return(SEMICOLON);
	      }

\=       {
            if (ldebug) printf("lex: equals symbol\n");
            yylval.ival = yytext[0];
            return(EQUALS);
         }

[a-zA-Z_][a-zA-Z0-9_]* {
	         if (ldebug) printf("lex: ID\n");
            yylval.str = strdup(yytext);
            return(ID);
	      }

\"[^\"]+\"  {
            if (ldebug) printf("lex: string (%s)\n", yytext);
            yylval.str = strdup(yytext);
            return(STRING);
         }

[0-9]+   {
            if (ldebug) printf("lex: number (%s)\n", yytext);
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


