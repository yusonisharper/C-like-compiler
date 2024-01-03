%{
#include <stdio.h>
#include <math.h>

unsigned long long current_line = 1;
unsigned long long current_column = 0;
#define YY_USER_ACTION current_column += yyleng;

#include "y.tab.c"

%}

%option noyywrap

nat                     [0-9]+
signedNat               [+-]?{nat}
decimalNum              {signedNat}"."{nat}
scientificNum           {decimalNum}"E"{signedNat}
NUMBER                  {signedNat}("."{nat})?("E"{signedNat})?

leter                   [a-zA-Z]
digit                   [0-9]
ID                      {leter}({leter}|{digit}|_)*
KEYWORD                 "if"|"else if"|"else"|"for"|"while"|"do"|"break"|"int"

arithmeticOP            "+"|"-"|"*"|"/"|"%"|"="|"++"|"--"
comparisonOP            "=="|"!="|">"|">="|"<"|"<="
bracket                 "("|")"|"["|"]"|"{"|"}"
SPEC_SYMBOL             ";"|","|"~"
COMMENT                 "//".*

%%

{COMMENT}       { /*printf("COMMENT %s\n", yytext); ignore comment, do nothing*/ }
"?"             {
                    printf("Error at line %11u, col %11u, unrecognized symbol \"?\"\n", current_line, current_column); 
                    yyterminate();
                }
":"             {
                    printf("Error at line %11u, col %11u, unrecognized symbol \":\"\n", current_line, current_column); 
                    yyterminate();
                }
";"             { return SEMI; }
","             { return COMMA; }

"+"             { return ADD; }
"-"             { return SUB; }
"*"             { return MUL; }
"/"             { return DIV; }
"%"             { return MOD; }
"="             { return ASSIGN; }

"=="            { return EQ; }          
"!="            { return NEQ; }
">"             { return GT; }
">="            { return GTE; }
"<"             { return LT; }
"<="            { return LTE; }

"("             { return L_PAREN; }           
")"             { return R_PAREN; }
"["             { return L_S_BRAC; }
"]"             { return R_S_BRAC; }
"{"             { return L_C_BRAC; }
"}"             { return R_C_BRAC; }

"if"            { return IF; }
"else"          { return ELSE; }
"for"           { return FOR; }
"while"         { return WHILE; }
"do"            { return DO; }
"break"         { return BREAK; }
"continue"      { return CONTINUE; }
"return"        { return RETURN; }
"input"         { return INPUT; }
"output"        { return OUTPUT; }
"int"           { return INT; }
"bool"          { return BOOL; }

{nat}{leter}+   {
                    printf("Error at line %11u, col %11u, identifier \"%s\" must begin with a letter\n", current_line, current_column, yytext); 
                    yyterminate();
                }
{nat}     { yylval.str = strdup(yytext); return NUM; } // NUMBER
{ID}            { yylval.str = strdup(yytext); return ID; }
\n              { ++current_line; current_column = 0; }
[ \t\r]         /*NOP */

.               { 
                    // note: fprintf(stderr, ""); more traditional for error reporting 
                    printf("problem at line %11u, col %11u\n", current_line, current_column); 
                    yyterminate();
                }

%%

int main(int argc, char **argv) {
    if(argc == 2 && !(yyin = fopen(argv[1], "r"))) {
        fprintf(stderr, " could not open input %s \n", argv[1]);
        return -1;
    }
    //yylex();
    yyparse();
    
    return 0;
}