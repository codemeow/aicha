#include <stdio.h>

//#define PUSH

#ifdef PUSH
const int ispush = 1;
#else
const int ispush = 0;
#endif // PUSH

int main()
{
    int i;
    
    if (ispush) // Push
    {
        printf("# Push\n");
        for (i = 1; i < 0x80; i++)
        {
            printf("MOV REGIST%02X REGIST%02X\n", i, i - 1);
        }
    }
    else // Pop
    {
        printf("# Restore\n");
        for (i = 0x7F; i >= 0; i--)
        {
            printf("MOV REGIST%02X REGIST%02X\n", i, i + 1);
        }
    }
}
