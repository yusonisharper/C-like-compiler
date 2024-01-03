%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
char *varArray[4096];
char *functionArray[4096];
int varCount = 0;
int functionCount = 0;

void yyerror(char const *err) { 
    fprintf(stderr, "Lyyerror: %s, (line %11u, col %11u)\n", err, current_line, current_column); 
    exit(-1); 
    }

static char* gencounter(int offset) {
    static unsigned long long counter;
    static char buff[4096];
    switch(offset) {
        case 0: { counter = 0; sprintf(buff, "%u", counter++);} break;
        default: { sprintf(buff, "%u", counter++);} break;
    }
    return strdup(buff);
}
static char* genTempName() {
    static unsigned long long counter;
    static char buff[4096]; sprintf(buff, "temp%u", counter++);
    return strdup(buff);
}
static char* genLabelName(int offset) {
    static unsigned long long counter;
    static char buff[4096];
    switch(offset) {
        case 0: {sprintf(buff, "label%u", counter++); } break;
        default: { sprintf(buff, "label%u", counter + offset); } break;
    }
    return strdup(buff);
}

typedef struct {
    char *parsing_name; // should not use this
    char *name;
    char *value;
    char *code;
    char *aname;
    char *idx;
    char *idxcode;
    
} VarData;

%}

//%define parse.error custom

%token NUM L_PAREN R_PAREN L_S_BRAC R_S_BRAC L_C_BRAC R_C_BRAC ID SEMI COMMA CONTINUE BREAK IF ELSE WHILE DO FOR INPUT OUTPUT RETURN
%token INT BOOL

%left ADD SUB MUL DIV MOD EQ NEQ GT GTE LT LTE
%right ASSIGN

%union {
    int num;
    char* str;
    VarData var;
}
/* num match the num in %union*/
%type<str> NUM
%type<str> INT BOOL ADD SUB MUL DIV MOD LT LTE arg ID type
%type<var> program function arguments stmts stmt assignment_exp while_loop do_while_loop for_loop BREAK CONTINUE if_else_stmt io_stmt parameters
%type<var> identifier lhs sub_declaration declaration_list arithmetic_exp sub_exp builder array_declaration expression_stmt
%type<var> function_call compound_stmt declaration array_access single_stmt argument_list expression array_index construct
%type<var> L_PAREN R_PAREN L_S_BRAC R_S_BRAC L_C_BRAC R_C_BRAC SEMI COMMA IF ELSE WHILE DO FOR INPUT OUTPUT
%type<str> EQ NEQ GT GTE RETURN

%%

construct: program{
    int i;
    int found = 0;
    for (i = 0; i < functionCount; i++)
    {
        if(!strcmp(functionArray[i], "main"))
        {
            found = 1;
        }
    }
    if(found == 0)
    {
        printf("There is no main funcion.(line %11u, col %11u) \n", current_line, current_column);
    }
    found = 0;
}

program : program builder { printf("endfunc\n\n"); 

    }
| builder {printf("endfunc\n\n"); 

}

builder: function {if($1.code != 0) printf("%s", $1.code);}
| declaration //{ printf("builder -> declaration\n"); }

function: type ID L_PAREN argument_list R_PAREN compound_stmt{
    char buf[81920];
    if ($4.code != 0 && $6.code != 0) {sprintf(buf, "func %s\n%s%s", $2, $4.code, $6.code);}
    else if ($4.code != 0) {sprintf(buf, "func %s\n%s", $2, $4.code);}
    else if ($6.code != 0) {sprintf(buf, "func %s\n%s", $2, $6.code);}
    $$.code = strdup(buf);

    functionArray[functionCount] = $2;
    functionCount = functionCount + 1;
}

type: INT //{ printf("type -> INT\n"); }
| BOOL //{ printf("type -> BOOL\n"); }

argument_list: arguments { $$.code = $1.code; }
| {/*NOP*/}

arguments: arguments COMMA arg {
    char buf[81920];
    char *counter = gencounter(1);
    if($1.code != 0) sprintf(buf, "%s. %s\n= %s, $%s\n", $1.code, $3, $3, counter);
    $$.code = strdup(buf);
    //printf("[%s]\n", buf);
}
| arg {
    char buf[81920];
    char *counter = gencounter(0);
    sprintf(buf, ". %s\n= %s, $%s\n", $1, $1, counter);
    $$.code = strdup(buf);
    }

arg: type ID L_S_BRAC R_S_BRAC //{ printf("arg -> type ID(%s) L_PAREN R_PAREN\n", $2); }
| type ID { $$ = $2; }

stmt: compound_stmt { $$.code = $1.code; }
| single_stmt { $$.code = $1.code; }

compound_stmt: L_C_BRAC stmts R_C_BRAC { $$.code = $2.code; }

stmts: stmts stmt {
    char buf[81920];
    if ($1.code != 0 && $2.code != 0) {sprintf(buf, "%s%s", $1.code, $2.code);}
    else if ($1.code != 0) {sprintf(buf, "%s", $1.code);}
    else if ($2.code != 0) {sprintf(buf, "%s", $2.code);}
    $$.code = strdup(buf);
}
| {$$.code = 0;}

single_stmt: declaration { $$.code = $1.code; }
| array_declaration { $$.code = $1.code; }
| function_call SEMI { $$.code = $1.code; }
| while_loop { $$.code = $1.code; }
| do_while_loop { $$.code = $1.code; }
| for_loop { $$.code = $1.code; }
| BREAK SEMI { $$.code = $1.code; }
| CONTINUE SEMI { $$.code = $1.code; }
| if_else_stmt { $$.code = $1.code; }
| io_stmt SEMI { $$.code = $1.code; }
| RETURN SEMI { char* t1 = genTempName(); char buf[81920]; sprintf(buf, ". %s\nret %s", t1, t1); $$.code = strdup(buf);}
| RETURN sub_exp SEMI { 
    char buf[81920]; 
    if ($2.code != 0)
        sprintf(buf, "%sret %s\n", $2.code, $2.value); 
    else
        sprintf(buf, "ret %s\n", $2.value); 
    $$.code = strdup(buf);}
| RETURN function_call SEMI {
    char buf[81920]; 
    if ($2.code != 0)
        sprintf(buf, "%sret %s\n", $2.code, $2.value); 
    else
        sprintf(buf, "ret %s\n", $2.value); 
    $$.code = strdup(buf);}
while_loop: WHILE L_PAREN expression R_PAREN stmt
{
    char *L1 = genLabelName(0); char *L2 = genLabelName(0); char *L3 = genLabelName(0);
    char buf[81920];

    if ($5.code != 0)
        sprintf(buf, ": %s\n%s?:= %s, %s\n:= %s\n: %s\n%s:= %s\n : %s\n", L3, $3.code, L2, $3.value, L1, L2, $5.code, L3, L1);
    else
        sprintf(buf, ": %s\n%s?:= %s, %s\n:= %s\n: %s\n:= %s\n : %s\n", L3, $3.code, L2, $3.value, L1, L2, L3, L1);
     $$.code = strdup(buf);
}

do_while_loop: DO stmt WHILE L_PAREN expression R_PAREN SEMI
{
    char *L1 = genLabelName(0);
    char buf[81920];

    if ($2.code != 0)
        sprintf(buf, ": %s\n%s%s?:= %s, %s\n", L1, $2.code, $5.code, L1, $5.value);
    else
        sprintf(buf, ": %s\n%s?:= %s, %s\n", L1, $5.code, L1, $5.value);
     $$.code = strdup(buf);
}

for_loop: FOR L_PAREN declaration expression_stmt expression R_PAREN stmt { 
    char *L1 = genLabelName(0); char *L2 = genLabelName(0); char *L3 = genLabelName(0);
    char buf[81920];

    if ($7.code != 0)

        sprintf(buf, "%s: %s\n%s?:= %s, %s\n:= %s\n: %s\n%s%s:= %s\n: %s\n", $3.code, L3, $4.code, L2, $4.value, L1, L2, $7.code, $5.code, L3, L1);
    else
        sprintf(buf, "%s: %s\n%s?:= %s, %s\n:= %s\n: %s\n%s:= %s\n: %s\n", $3.code, L3, $4.code, L2, $4.value, L1, L2, $5.code, L3, L1);
    $$.code = strdup(buf);
    }

if_else_stmt: IF L_PAREN expression R_PAREN stmt 
{
    char *L1 = genLabelName(0); char *L2 = genLabelName(0);
    char buf[81920];
    if ($5.code != 0)//|exp                      |stmt
        sprintf(buf, "%s?:= %s, %s\n:= %s\n: %s\n%s: %s\n", $3.code, L2, $3.value, L1, L2, $5.code, L1);
    else
        sprintf(buf, "%s?:= %s, %s\n:= %s\n: %s\n: %s\n", $3.code, L2, $3.value, L1, L2, L1);
    $$.code = strdup(buf);
}
| IF L_PAREN expression R_PAREN stmt ELSE stmt
{
    char *L1 = genLabelName(0); char *L2 = genLabelName(0); char *L3 = genLabelName(0);
    char buf[81920];
    if ($5.code != 0)//|exp                       |stmt          |else_stmt
        sprintf(buf, "%s?:= %s, %s\n:= %s\n: %s\n%s:= %s\n: %s\n%s: %s\n", $3.code, L2, $3.value, L1, L2, $5.code, L3, L1, $7.code, L3);
    $$.code = strdup(buf);
}

io_stmt: INPUT ID { char buf[81920]; sprintf(buf, ".< %s\n", $2); $$.code = strdup(buf); }
| OUTPUT array_access { char buf[81920]; sprintf(buf, "%s.> %s\n", $2.code, $2.value); $$.code = strdup(buf); }
| OUTPUT ID { char buf[81920]; sprintf(buf, ".> %s\n", $2); $$.code = strdup(buf); }


declaration: type declaration_list SEMI {
    char buf[81920];
    if ($2.code != 0)
        sprintf(buf, "%s%s", $2.name, $2.code);
    else
        sprintf(buf, "%s", $2.name);
    $$.code = strdup(buf);

    int i;
    int found = 0;
    for (i = 0; i < varCount; i++)
    {
        if(($2.name != 0 && !strcmp($2.name, varArray[i])) || ($2.aname != 0 && !strcmp($2.aname, varArray[i]))){
            found = 1;
            printf("This variable %s has been declared already.(line %11u, col %11u) \n", $2.name, current_line, current_column);
            break;
        }

    }
    found = 0;

    varArray[varCount] = strdup($2.name);
    varCount = varCount + 1;

    }
| declaration_list SEMI { if ($1.code != 0) $$.code = $1.code; 

    int i;
    int found = 0;
    for (i = 0; i < varCount; i++)
    {
        if(($1.name != 0 && !strcmp($1.name, varArray[i])) || ($1.aname != 0 && !strcmp($1.aname, varArray[i]))){
            found = 1;
            break;
        }

    }
    if(found == 0)
    {
        printf("This variable %s has not been declared yet.(line %11u, col %11u) \n", $1.name, current_line, current_column);
    }
    found = 0;
}

declaration_list: declaration_list COMMA sub_declaration {
    char nbuf[20480];
    if ($1.name != 0 && $3.name != 0)
        sprintf(nbuf, "%s. %s\n", $1.name, $3.name);
    else if ($1.name != 0)
        sprintf(nbuf, "%s", $1.name);
    else if ($3.name != 0)
        sprintf(nbuf, ". %s\n", $3.name);
    $$.name = nbuf;
    char buf[81920];
    if ($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s", $1.code, $3.code);
    else if ($1.code != 0)
        sprintf(buf, "%s", $1.code);
    else if ($3.code != 0)
        sprintf(buf, "%s", $3.code);
    $$.code = strdup(buf);
}
| sub_declaration 
{   
    char nbuf[2048];
    if ($1.aname == 0)
    {
        sprintf(nbuf, ". %s\n", $1.name); 
        $$.name = nbuf; $$.code = $1.code;
    }
    else
    {
        sprintf(nbuf, ".[] %s, %s\n", $1.aname, $1.idx);
        $$.name = nbuf;
    }
}


sub_declaration: assignment_exp { $$.code = $1.code; }
| identifier { $$.name = $1.name; }

array_declaration: type array_access SEMI 
{
    varArray[varCount] = strdup($2.aname);
    varCount = varCount + 1;
    char nbuf[2048];
    if ($2.idxcode != 0)
        sprintf(nbuf, "%s.[] %s, %s\n", $2.idxcode, $2.aname, $2.idx);
    else
        sprintf(nbuf, ".[] %s, %s\n", $2.aname, $2.idx);
    $$.code = strdup(nbuf);

    if(atoi($2.idx) <= 0)
    {
        printf("The size of array cannot be less or equal to 0.\n");
    }
}

expression_stmt: expression SEMI {$$.code = $1.code; $$.value = $1.value; }//{ printf("expression_stmt -> expression SEMI\n");}
| SEMI //{ printf("expression_stmt -> SEMI\n"); }

expression: expression COMMA sub_exp //{ printf("expression -> expression COMMA sub_exp\n"); }
| sub_exp {$$.value = $1.value; $$.code = strdup($1.code); }

sub_exp: sub_exp GT sub_exp 
{   char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n> %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n> %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n> %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n> %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| sub_exp LT sub_exp
{   char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n< %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n< %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n< %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n< %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| sub_exp GTE sub_exp 
{   char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n>= %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n>= %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n>= %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n>= %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| sub_exp LTE sub_exp 
{   char* t1 = genTempName(); $$.value = t1; printf(". %s\n", t1); 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n<= %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n<= %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n<= %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n<= %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
    }
| sub_exp EQ sub_exp 
{   char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n== %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n== %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n== %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n== %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| sub_exp NEQ sub_exp 
{   char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n!= %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n!= %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n!= %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n!= %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| L_PAREN sub_exp R_PAREN { $$.value = $2.value; $$.code = $2.code; }
| arithmetic_exp { $$.value = $1.value; $$.code = $1.code; }
| assignment_exp { $$.code = $1.code; }

assignment_exp: lhs assign_op sub_exp
{ 
    char buf[81920];
    if ($1.aname == 0)
    {
        if($3.code != 0 && $1.code != 0)
            sprintf(buf, "%s%s= %s, %s\n", $1.code, $3.code, $1.name, $3.value);
        else if ($3.code != 0 && $1.idxcode == 0)
            sprintf(buf, "%s= %s, %s\n", $3.code, $1.name, $3.value);
        else if ($1.idxcode != 0 && $3.code == 0)
            sprintf(buf, "%s= %s, %s\n", $1.code, $1.name, $3.value);
        else
            sprintf(buf, "= %s, %s\n", $1.name, $3.value);
        $$.code = strdup(buf);
    }
    else
    {
        if($3.code != 0 && $1.idxcode != 0)
            sprintf(buf, "%s%s[]= %s, %s, %s\n", $1.idxcode, $3.code, $1.aname, $1.idx, $3.value);
        else if ($3.code != 0 && $1.idxcode == 0)
            sprintf(buf, "%s[]= %s, %s, %s\n", $3.code, $1.aname, $1.idx, $3.value);
        else if ($1.idxcode != 0 && $3.code == 0)
            sprintf(buf, "%s[]= %s, %s, %s\n", $1.idxcode, $1.aname, $1.idx, $3.value);
        else
            sprintf(buf, "[]= %s, %s, %s\n", $1.aname, $1.idx, $3.value);
        $$.code = strdup(buf);
    }
}
| lhs assign_op array_access
{ 
    char buf[81920];
    if ($1.aname == 0)
    {
        if ($1.code != 0 && $3.idxcode != 0)
            sprintf(buf, "%s%s%s= %s, %s\n", $1.code, $3.idxcode, $3.code, $1.name, $3.value);
        else if ($1.code == 0 && $3.idxcode != 0)
            sprintf(buf, "%s%s= %s, %s\n", $3.idxcode, $3.code, $1.name, $3.value);
        else if ($1.code != 0 && $3.idxcode == 0)
            sprintf(buf, "%s%s= %s, %s\n", $1.code, $3.code, $1.name, $3.value);
        else
            sprintf(buf, "%s= %s, %s\n", $3.code, $1.name, $3.value);
        $$.code = strdup(buf);
    }
    else
    {
        if ($1.idxcode != 0 && $3.idxcode != 0)
            sprintf(buf, "%s%s%s= %s, %s\n", $1.idxcode, $3.code, $3.idxcode, $1.name, $3.value);
        else if ($1.idxcode == 0 && $3.idxcode != 0)
            sprintf(buf, "%s[]= %s, %s, %s\n", $3.code, $1.aname, $1.idx, $3.value);
        else if ($1.idxcode != 0 && $3.idxcode == 0)
            sprintf(buf, "%s= %s, %s\n", $1.idxcode, $1.name, $3.value);
        else
            sprintf(buf, "= %s, %s\n", $1.name, $3.value);
        $$.code = strdup(buf);
    }
}
| lhs assign_op function_call
{ 
    char buf[81920];
    if ($1.aname == 0)
    {
        if($3.code != 0 && $1.code != 0)
            sprintf(buf, "%s%s= %s, %s\n", $1.code, $3.code, $1.name, $3.value);
        else if ($3.code != 0 && $1.idxcode == 0)
            sprintf(buf, "%s= %s, %s\n", $3.code, $1.name, $3.value);
        else if ($1.idxcode != 0 && $3.code == 0)
            sprintf(buf, "%s= %s, %s\n", $1.code, $1.name, $3.value);
        else
            sprintf(buf, "= %s, %s\n", $1.name, $3.value);
        $$.code = strdup(buf);
    }
    else
    {
        if($3.code != 0 && $1.idxcode != 0)
            sprintf(buf, "%s%s[]= %s, %s, %s\n", $1.idxcode, $3.code, $1.aname, $1.idx, $3.value);
        else if ($3.code != 0 && $1.idxcode == 0)
            sprintf(buf, "%s[]= %s, %s, %s\n", $3.code, $1.aname, $1.idx, $3.value);
        else if ($1.idxcode != 0 && $3.code == 0)
            sprintf(buf, "%s[]= %s, %s, %s\n", $1.idxcode, $1.aname, $1.idx, $3.value);
        else
            sprintf(buf, "[]= %s, %s, %s\n", $1.aname, $1.idx, $3.value);
        $$.code = strdup(buf);
    }
}

lhs: identifier { $$.name = $1.name; $$.value = $1.value; }
| array_access { $$.aname = $1.aname; $$.idx = $1.idx; }

identifier: ID { $$.name = $1; $$.value = $1; }

assign_op: ASSIGN //{ printf("assign_op -> ASSIGN\n"); }
/*| ADD //{ printf("assign_op -> ADD\n"); }
| SUB //{ printf("assign_op -> SUB\n"); }
| MUL //{ printf("assign_op -> MUL\n"); }
| DIV //{ printf("assign_op -> DIV\n"); }
| MOD //{ printf("assign_op -> MOD\n"); }*/

arithmetic_exp: arithmetic_exp ADD arithmetic_exp 
{
    char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n+ %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n+ %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n+ %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n+ %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| arithmetic_exp SUB arithmetic_exp
{
    char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n- %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n- %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n- %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n- %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| arithmetic_exp MUL arithmetic_exp 
{
    char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n* %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n* %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n* %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n* %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| arithmetic_exp DIV arithmetic_exp
{
    char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n/ %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n/ %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n/ %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n/ %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| arithmetic_exp MOD arithmetic_exp
{
    char* t1 = genTempName(); $$.value = t1; 
    char buf[81920];
    if($1.code != 0 && $3.code != 0)
        sprintf(buf, "%s%s. %s\n%% %s, %s, %s\n", $1.code, $3.code, t1, t1, $1.value, $3.value);
    else if($1.code != 0)
        sprintf(buf, "%s. %s\n%% %s, %s, %s\n", $1.code, t1, t1, $1.value, $3.value);
    else if($3.code != 0)
        sprintf(buf, "%s. %s\n%% %s, %s, %s\n", $3.code, t1, t1, $1.value, $3.value);
    else
        sprintf(buf, ". %s\n%% %s, %s, %s\n", t1, t1, $1.value, $3.value);
    $$.code = strdup(buf);
}
| L_PAREN arithmetic_exp R_PAREN { $$.value = $2.value; $$.code = $2.code; }
| array_access { $$.value = $1.value; $$.code = $1.code; }
| identifier { $$.value = $1.value; $$.name = $1.name; }
| NUM { $$.value = $1; $$.name = $1; }

array_access: identifier L_S_BRAC array_index R_S_BRAC 
{ 
    char* t1 = genTempName(); $$.value = t1;
    char buf[81920];
    if($3.code != 0)
        sprintf(buf, "%s. %s\n=[] %s, %s, %s\n", $3.code, t1, t1, $1.name, $3.value);
    else
        sprintf(buf, ". %s\n=[] %s, %s, %s\n", t1, t1, $1.name, $3.value);
    $$.code = strdup(buf);
    $$.aname = $1.name;
    $$.idx = $3.value;
    $$.idxcode = $3.code;
}

array_index: arithmetic_exp { $$.value = $1.value; $$.code = $1.code; }

function_call: identifier L_PAREN parameters R_PAREN 
{   char* t1 = genTempName(); $$.value = t1;
    char buf[81920];
    sprintf(buf, ". %s\n%scall %s, %s\n", t1, $3.code, $1.name, t1);
    $$.code = strdup(buf);

    int i;
    int found = 0;
    for (i = 0; i < functionCount; i++)
    {
        int cmp;
        cmp = strcmp($1.name, functionArray[i]);
        if(!cmp)
        {
            found = 1;
            break;
        }
    }
    if(found == 0)
    {
        printf("This function %s has not been defined yet.(line %11u, col %11u) \n", $1.name,  current_line, current_column);
    }
    found = 0;
    }

parameters: parameters COMMA sub_exp {
    char buf[81920];
    if($1.code != 0)
        sprintf(buf, "%sparam %s\n", $1.code, $3.name);
    else
        sprintf(buf, "param %s\n", $3.name);
    $$.code = strdup(buf);
}
| sub_exp{ 
    char buf[81920];
    if($1.code != 0)
        sprintf(buf, "%sparam %s\n", $1.code, $1.name);
    else
        sprintf(buf, "param %s\n", $1.name);
    $$.code = strdup(buf);
    }

%%