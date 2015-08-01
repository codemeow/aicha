# Aicha
Aicha Programming Language Interpreter

# Commands

## MOV [p1] [p2]
P1 = P2

## NOR [p1] [p2]
P1 = ~(P1 | P2)

## SHL [p1] [p2]
P1 = P1 << P2

## SHR [p1] [p2]
P1 = P1 >> P2

## NOP
Does nothing

# Memory
256 registers, REGIST00-REGIST7F are user registers, REGIST80-REGISTFC are system registers. REGISTFD and REGISTFE are input registers, the input parameters of the any extension function will be stored there. REGISTFD is also output register, the result of the extension function is supposed to be trasfered via it. That means that after the extension function call you have to grab and copy the result somewhere else. REGISTFF stores current position of the caret, that allows to use it to make loops and conditions.

# Extensions
Extension - is a file that contains instructions. System extensions are in ./sys and user extensions are in ./usr directories. The system directory has higher priority.

# Interpreter
Calling scheme: main.sh [file to process] [mode] [output file (optional)] [initialiser]
Mode could be HEX, INTS or ASCII, that defines the output format of all registers after the interperting is done. Initialiser defines the starting value of all (except REGISTFF) registers before start.
