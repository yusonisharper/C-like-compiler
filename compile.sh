flex jun.lex

bison -v -d --file-prefix=y jun.y

gcc -O3 lex.yy.c -o parser.elf

./parser.elf ./input.txt > output.mil

rm lex.yy.c y.output y.tab.c y.tab.h parser.elf