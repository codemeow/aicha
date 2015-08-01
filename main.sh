#!/bin/bash

# USE: main.sh MUL.aic INTS ./output.out DEADBEEF
#        $0      $1      $2      $3        $4
#     filename command mode    output   initialiser
#      [M]       [M]    [M]     [O]        [O]

PAR0="$0"
PAR1="$1"
PAR2="$2"
PAR3="$3"
PAR4="$4"

if [ -z "$PAR1" ] || [ -z "$PAR2" ]
then
    echo "Aicha v.0.2 LGPL v3, by ATiger"
    echo "Use: main.sh <file> <format>"
    echo "Allowed formats: ASCII, HEX, INTS"
    exit 0
fi

if [ "$PAR2" == "HEX" ]
then
   FORMAT="HEX"
   PAR2="0"
elif [ "$PAR2" == "ASCII" ]
then
   FORMAT="ASCII"
   PAR2="0"
elif [ "$PAR2" == "INTS" ]
then
   FORMAT="INTS"
   PAR2="0"
fi

if [ -z "$PAR3" ]
then
    OUTPUT="./output.txt"
else
    OUTPUT="$PAR3"
fi

if [ -z "$PAR4" ]
then
    INITER="00000000"
else
    INITER="$PAR4"
fi

# ## Registers table
# # REGIST00 - REGIST7F - For user use
# # REGIST80 - REGISTFC - For system use
# # REGISTFD            - lvalue parameter for custom functions also output register
# # REGISTFE            - rvalue parameter for custom functions
# # REGISTFF            - Caret pos

REGISTLEFT="REGISTFD"
REGISTRGHT="REGISTFE"

mkdir sys 2>/dev/null
mkdir usr 2>/dev/null

if [ "$PAR2" -eq 0 ]
then
    echo "# Creating registers"
    mkdir registers 2>/dev/null
    rm -f ./registers/*
    for ((i=0; i < 0xFF ; i++))
    do
      echo "$INITER" > "./registers/REGIST$(printf %02X $i)"
    done
    echo "00000000" > "./registers/REGISTFF"
fi
      
for ((i=0; i < "$PAR2"; i++)) do echo -n "тФВ"; done; echo "тФМтФАтФАтФА"
for ((i=0; i < "$PAR2"; i++)) do echo -n "тФВ"; done; echo -n "тФВ"
basename "$PAR1" .aic

OLDIFS="$IFS"
IFS=$'\n' read -d '' -r -a LINES < "$PAR1"
IFS="$OLDIFS"

echo "00000000" > ./registers/REGISTFF

while (( ${#LINES[@]} >  0x$(cat ./registers/REGISTFF)))
do
    line="${LINES[0x$(cat ./registers/REGISTFF)]}"

    command=$(echo $line | cut -d' ' -f1)
     lvalue=$(echo $line | cut -d' ' -f2)
     rvalue=$(echo $line | cut -d' ' -f3)

    case "$command" in
        "MOV" ) 
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )
                            if [ "$rvalue" != "$lvalue" ] 
                            then                         
                                cat "./registers/$rvalue" > "./registers/$lvalue"
                            fi;;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                            if [ "$rvalue" != "$lvalue" ] 
                            then                         
                                echo "$rvalue" > "./registers/$lvalue"
                            fi;;
                     esac;;
                * ) exit 2;;
            esac;;         
        "SHL" )
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )
                     T=$((0x$(cat "./registers/$lvalue")))
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )                     
                             T=$(($T << $((0x$(cat "./registers/$rvalue"))) & 0xFFFFFFFF));;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                             T=$(($T << $((0x$rvalue)) & 0xFFFFFFFF));;
                     esac
                     printf %08X $T > "./registers/$lvalue";;
                * ) exit 2;;  
            esac;;
        "SHR" )
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )
                     T=$((0x$(cat "./registers/$lvalue")))
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )                     
                             T=$(($T >> $((0x$(cat "./registers/$rvalue")))));;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                             T=$(($T >> $((0x$rvalue))));;
                     esac
                     printf %08X $T > "./registers/$lvalue";;
                * ) exit 2;;  
            esac;;
        "NOR" )
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )                
                     T=$((0x$(cat "./registers/$lvalue")))
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )                     
                             T=$(($((~$(($T | $((0x$(cat "./registers/$rvalue"))))))) & 0xFFFFFFFF));;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                             T=$((~$(($(($T | $((0x$rvalue)))))) & 0xFFFFFFFF));;
                     esac
                     printf %08X $T > "./registers/$lvalue";;
                * ) exit 2;;  
            esac;;
        "NOP" ) ;;        
        [A-Z][0-9A-Z][0-9A-Z] )
            echo "Custom"
            if [ -n $lvalue ]
            then
                case "$lvalue" in
                    "REGIST"[0-9A-F][0-9A-F] )
                        if [ "$lvalue" != "$REGISTLEFT" ] 
                        then                         
                            cat "./registers/$lvalue" > "./registers/$REGISTLEFT"
                        fi;;
                    [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )                 
                        echo "$lvalue" > "./registers/$REGISTLEFT";;
                esac
            fi
            if [ -n $rvalue ]
            then 
                case "$rvalue" in
                    "REGIST"[0-9A-F][0-9A-F] )
                        if [ "$rvalue" != "$REGISTRGHT" ] 
                        then                         
                            cat "./registers/$rvalue" > "./registers/$REGISTRGHT"
                        fi;;
                    [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] ) 
                        echo "$rvalue" > "./registers/$REGISTRGHT";;
                esac
            fi
        
            if [ -n "$(find ./sys/ -name "$command.aic" | tr -d "\n")" ]
            then                
                OLDCARET=$((0x$(cat ./registers/REGISTFF)))
                sh ./main.sh "./sys/$command.aic" $(($2 + 1))
                printf %08X "$OLDCARET" > "./registers/REGISTFF"
            elif [ -n "$(find ./usr/ -name "$command.aic" | tr -d "\n")" ]
            then
                OLDCARET=$((0x$(cat ./registers/REGISTFF)))
                sh ./main.sh "./usr/$command.aic" $(($2 + 1))
                printf %08X "$OLDCARET" > "./registers/REGISTFF"
            else
                echo "ERR: Command \"$command\" not found"
                exit 2;
            fi;;
    esac
    
    TT=$((0x$(cat ./registers/REGISTFF) + 1))
    printf %08X "$TT" > "./registers/REGISTFF"
done

for ((i=0; i < "$PAR2"; i++)) do echo -n "тФВ"; done; echo "тФФтФАтФАтФА"

if [ "$PAR2" -eq 0 ]
then
    echo "# Creating output"
    rm -f "$OUTPUT"
    case "$FORMAT" in
    "ASCII" ) 
        for ((i=0; i <= 0xFF; i++))
        do
            cat "./registers/REGIST$(printf %02X $i)" | tr -d "\n" | sed 's/../\\\\x&/g' | xargs echo -ne >> "$OUTPUT"
            if [ $((i % 16)) -eq 15 ]
            then
                echo >> "$OUTPUT"
            fi
        done;;
    "HEX"   )
        for ((i=0; i <= 0xFF; i++))
        do
            cat "./registers/REGIST$(printf %02X $i)" | tr -d "\n" >> "$OUTPUT"
            if [ $((i % 8)) -eq 7 ]
            then
                echo >> "$OUTPUT"
            fi
        done;;
    "INTS"  ) 
        for ((i=0; i <= 0xFF; i++))
        do
            cat "./registers/REGIST$(printf %02X $i)" | tr -d "\n" >> "$OUTPUT"
            echo -n " " >> "$OUTPUT"
            if [ $((i % 8)) -eq 7 ]
            then
                echo >> "$OUTPUT"
            fi
        done;;
    esac
    rm -f ./registers/*
fi
