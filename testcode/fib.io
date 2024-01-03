int fib(int num){
    if(num == 1) return 1;
    if(num == 2) return 1;
    int counter = num - 3;
    int fib_num[100];
    fib_num[num - 1] = 1; fib_num[num - 2] = 1;
    while(counter >= 0){
        fib_num[counter] = fib_num[counter + 1] + fib_num[counter + 2];
        counter = counter - 1;
    }
    return fib_num[counter + 1];
}

int main() {
  int a = 8;
  int b = fib(a);
  output b;

}