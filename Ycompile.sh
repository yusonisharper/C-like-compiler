flex wang.lex

bison -v -d --file-prefix=y wang.y

gcc -O3 lex.yy.c -o parser.elf

#./parser.elf ./test/bubble.io > bubble.mil
#./parser.elf ./test/fib.io > fib.mil
./parser.elf ./test/test.io > test.mil

./mil_run test.mil

rm lex.yy.c y.tab.c y.output y.tab.h parser.elf
