int main(){
  int size = 5;
  int arr[5];
  arr[0] = 10;
  arr[1] = 5;
  arr[2] = 9;
  arr[3] = 4;
  arr[4] = 1;

int i;
int j;
int temp;

for(i = 0; i < size - 1; i = i + 1)
  {
  for(j = 0; j < size - i - 1; j = j + 1)
    {
      if(arr[j] > arr[j + 1])
        {
            temp = arr[j];
            arr[j] = arr[j + 1];
            arr[j + 1] = temp;
        }
    }
  } 

  output arr[0];
  output arr[1];
  output arr[2];
  output arr[3];
  output arr[4];

}