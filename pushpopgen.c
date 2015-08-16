#include <stdio.h>

int main()
{
    int i;
    
    // Push
    // MOV 7F 7E
    // MOV 7E 7D
    // ...
    // MOV 01 00
    
    printf("# Push\n");
    for (i = 0x7F; i > 0; i--)
    {
        printf("MOV REGIST%02X REGIST%02X\n", i, i - 1);
    }
        
    // Pop
    // MOV 00 01
    // MOV 01 02
    // ...
    // MOV 7E 7F
    
    printf("# Restore\n");
    for (i = 0; i < 0x7F; i++)
    {
        printf("MOV REGIST%02X REGIST%02X\n", i, i + 1);
    }    
}
