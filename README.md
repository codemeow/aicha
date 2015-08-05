# Aicha
Aicha Programming Language Interpreter

# Commands

## MOV [p1] [p2]
`P1 = P2`

## NOR [p1] [p2]
`P1 = P1 ↓ P2`

## SHL [p1] [p2]
`P1 = P1 << P2`

## SHR [p1] [p2]
`P1 = P1 >> P2`

## NOP
Does nothing

# Memory
256 registers, named `REGIST00-REGISTFF`. `REGISTFF` stores current position of the caret, that allows to use it to make loops and conditions. `REGISTFD` and `REGISTFE` store LValue and RValues of the called extension. Other registers are free to use.

# Extensions
Extension - is a file that contains instructions. System extensions are in `./sys` and user extensions are in `./usr` directories. The system directory has higher priority.

# Interpreter
Calling scheme: 
```Shell
main.sh [file to process] [mode] [output file (optional)] [initialiser(optional)] [debug mode(optional)]
```
Mode could be `HEX`, `INTS` or `ASCII`, that defines the output format of all registers after the interperting is done. Initialiser defines the starting value of all (except `REGISTFF`) registers before start.
Debug mode could be `RELEASE` or `DEBUG`. In `DEBUG` mode the interpreter will print lines that starts with "# "
