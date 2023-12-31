/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr = string_buf;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
%}

%x IN_COMMENT
%x IN_STRING
%x IN_REVERSE

/*
 * Define names for regular expressions here.
 */

SLINECOMMENT    --.*$
MLINECOMMENT    \(\*

WHITESPACE      [ \f\r\t\v]
NEWLINE         \n

DIGIT           [0-9]
DIGITS          [0-9]+

CLABEL          [A-Z]
LLABEL          [a-z]
LABEL           [a-zA-Z]
IDLABEL         [a-zA-Z_0-9]

TYPEID          {CLABEL}{IDLABEL}*
OBJID           {LLABEL}{IDLABEL}*

DARROW          =>
ASSIGN          <-
LE              <=
CLASS           [cC][lL][aA][sS][sS]
ELSE            [eE][lL][sS][eE]
FI              [fF][iI]
IF              [iI][fF]
IN              [iI][nN]
INHERITS        [iI][nN][hH][eE][rR][iI][tT][sS]
ISVOID          [iI][sS][vV][oO][iI][dD]
LET             [lL][eE][tT]
LOOP            [lL][oO][oO][pP]
POOL            [pP][oO][oO][lL]
THEN            [tT][hH][eE][nN]
WHILE           [wW][hH][iI][lL][eE]
CASE            [cC][aA][sS][eE]
ESAC            [eE][sS][aA][cC]
NEW             [nN][eE][wW]
OF              [oO][fF]
NOT             [nN][oO][tT]
TRUE            t[rR][uU][eE]
FALSE           f[aA][lL][sS][eE]

%%

 /*
  *  Nested comments
  */
{SLINECOMMENT} {}
{MLINECOMMENT} { BEGIN(IN_COMMENT); }
<IN_COMMENT>{
\*\)          BEGIN(INITIAL);
[^*\n]+
\*
<<EOF>>       { BEGIN(INITIAL); yylval.error_msg = "EOF in comment"; return ERROR; }
\n            curr_lineno++;
}

{WHITESPACE} {}
{NEWLINE} { curr_lineno++; }

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return DARROW; }
{ASSIGN}		{ return ASSIGN; }
{LE}	    	{ return LE; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}     { return CLASS; }           
{ELSE}      { return ELSE; }            
{FI}        { return FI; }              
{IF}        { return IF; }              
{IN}        { return IN; }              
{INHERITS}  { return INHERITS; }        
{ISVOID}    { return ISVOID; }         
{LET}       { return LET; }             
{LOOP}      { return LOOP; }            
{POOL}      { return POOL; }            
{THEN}      { return THEN; }            
{WHILE}     { return WHILE; }           
{CASE}      { return CASE; }            
{ESAC}      { return ESAC; }            
{NEW}       { return NEW; }             
{OF}        { return OF; }              
{NOT}       { return NOT; }             
{TRUE}      { yylval.boolean = true;  return BOOL_CONST;  }
{FALSE}     { yylval.boolean = false; return BOOL_CONST; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\" { BEGIN(IN_STRING); }
<IN_STRING>{
\0        { cool_yylval.error_msg = "String contains null character"; BEGIN(INITIAL); return ERROR; }
<<EOF>>   { cool_yylval.error_msg = "EOF in string constant"; BEGIN(INITIAL); return ERROR; }
\" {
  yylval.symbol = stringtable.add_string(string_buf, string_buf_ptr - string_buf);
  string_buf_ptr = string_buf;
  BEGIN(INITIAL);
  return STR_CONST;
}
\\ {
  BEGIN(IN_REVERSE);
}
\n {
  cool_yylval.error_msg = "Unterminated string constant";
  string_buf_ptr = string_buf;
  ++curr_lineno;
  BEGIN(INITIAL);
  return ERROR;
}
.   { *string_buf_ptr = yytext[0]; string_buf_ptr++; }
}
<IN_REVERSE>{
\0  { cool_yylval.error_msg = "String contains null character"; BEGIN(IN_STRING); return ERROR; }
<<EOF>> { cool_yylval.error_msg = "EOF in string constant"; BEGIN(IN_STRING); return ERROR; }
n   { *string_buf_ptr = '\n'; string_buf_ptr++; BEGIN(IN_STRING); }
b   { *string_buf_ptr = '\b'; string_buf_ptr++; BEGIN(IN_STRING); }
t   { *string_buf_ptr = '\t'; string_buf_ptr++; BEGIN(IN_STRING); }
f   { *string_buf_ptr = '\f'; string_buf_ptr++; BEGIN(IN_STRING); }
\n  { curr_lineno++; BEGIN(IN_STRING); }
.   { *string_buf_ptr = yytext[0]; string_buf_ptr++; BEGIN(IN_STRING); }
}


 /*
  * Integer, Identifiers, and Special Notation
  */
{DIGITS} {
  yylval.symbol = inttable.add_string(yytext, yyleng);
  return INT_CONST;
}

{TYPEID} {
  yylval.symbol = idtable.add_string(yytext, yyleng);
  return TYPEID;
}
{OBJID} {
  yylval.symbol = idtable.add_string(yytext, yyleng);
  return OBJECTID;
}

. { return yytext[0]; }

%%
