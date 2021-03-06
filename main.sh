#!/bin/bash

# «Aicha Intepreter» - Shell interpreter for Aicha programming language
##
##  Project Aicha is free software: you can redistribute it and/or modify
##  it under the terms of the GNU Lesser General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  Project Aicha is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU Lesser General Public License for more details.
##
##  You should have received a copy of the GNU Lesser General Public License
##  along with Project Aicha. If not, see <http://www.gnu.org/licenses/>.

# USE: main.sh MUL.aic INTS ./output.out DEADBEEF     DEBUG        DEEPNESS
#        $0      $1      $2      $3        $4          $5            $6
#     filename command mode    output   initialiser debug messages deepness
#      [M]       [M]    [M]     [O]        [O]         [O]         [HIDDEN]

PAR0="$0"
PAR1="$1"
PAR2="$2"
PAR3="$3"
PAR4="$4"
PAR5="$5"
PAR6="$6"

if [ -z "$PAR1" ] || [ -z "$PAR2" ]
then
    echo "Aicha v.0.2 LGPL v3, by ATiger"
    echo "Use: main.sh <file> <format> <output file (opt)> <initialiser (opt)> <debug mode(opt)>"
    echo "Allowed formats: ASCII, HEX, INTS"
    echo "Allowed initialiser: 00000000..FFFFFFFF"
    echo "Allowed debug modes: DEBUG or RELEASE"
    exit 0
fi

if [ ! -f "$PAR1" ]
then
    echo "ERR: input file does not exist"
    exit 2;
fi

if [ "$PAR2" == "HEX" ]
then
   FORMAT="HEX"
elif [ "$PAR2" == "ASCII" ]
then
   FORMAT="ASCII"
elif [ "$PAR2" == "INTS" ]
then
   FORMAT="INTS"
else
   echo "ERR: Unknown output format"
   exit 2
fi

if [ -z "$PAR6" ]
then
    DEEPNESS=0
else
    DEEPNESS="$PAR6"
fi

if [ -z "$PAR3" ] && [ "$DEEPNESS" = 0 ]
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

if [ -z "$PAR5" ]
then
    DEBUG_MODE="RELEASE"
else
    if [[ "DEBUG RELEASE" =~ "$PAR5" ]]
    then
        DEBUG_MODE="$PAR5"
    else
        echo "ERR: Bad debug mode"
        exit 2
    fi
fi

createOutput() {
    echo "# Creating output"
    rm -f "$OUTPUT"
    case "$FORMAT" in
    "ASCII" ) 
        for ((i=0; i <= 0xFF; i++))
        do
            cat "/dev/shm/aicha/registers/REGIST$(printf %02X $i)" | tr -d "\n" | sed 's/../\\\\x&/g' | xargs echo -ne >> "$OUTPUT"
            if [ $((i % 16)) -eq 15 ]
            then
                echo >> "$OUTPUT"
            fi
        done;;
    "HEX"   )
        for ((i=0; i <= 0xFF; i++))
        do
            cat "/dev/shm/aicha/registers/REGIST$(printf %02X $i)" | tr -d "\n" >> "$OUTPUT"
            if [ $((i % 8)) -eq 7 ]
            then
                echo >> "$OUTPUT"
            fi
        done;;
    "INTS"  ) 
        for ((i=0; i <= 0xFF; i++))
        do
            printf "%02X: " $i >> "$OUTPUT"
            cat "/dev/shm/aicha/registers/REGIST$(printf %02X $i)" | tr -d "\n" >> "$OUTPUT"
            echo -n " " >> "$OUTPUT"
            if [ $((i % 8)) -eq 7 ]
            then
                echo >> "$OUTPUT"
            fi
        done;;
    esac
}

## Registers table
# REGIST00 - REGIST7F - For user use
# REGIST80 - REGISTFC - For system use
# REGISTFD            - lvalue parameter for custom functions also output register
# REGISTFE            - rvalue parameter for custom functions
# REGISTFF            - Caret pos

REGISTLEFT="REGISTFD"
REGISTRGHT="REGISTFE"

mkdir sys 2>/dev/null
mkdir usr 2>/dev/null
mkdir -p /dev/shm/aicha/registers

if [ "$DEEPNESS" == 0 ]
then
    echo "# Creating registers"
    mkdir registers 2>/dev/null
    rm -f /dev/shm/aicha/registers/*
    
    for ((i=0; i <= 0xFF; i++))
    do
        echo "$INITER" > /dev/shm/aicha/registers/REGIST"$(printf %02X $i)"
    done
fi
      
for ((i=0; i < "$DEEPNESS"; i++)) do echo -n "│"; done; echo "┌───"
for ((i=0; i < "$DEEPNESS"; i++)) do echo -n "│"; done; echo -n "│"
basename "$PAR1" .aic

lines=( )
while IFS= read -r line 
do
  lines+=( "$line" )
done < "$PAR1"
[[ -n $line ]] && lines+=( "$line" )

echo "00000000" > /dev/shm/aicha/registers/REGISTFF

while (( ${#lines[@]} > 0x$(cat /dev/shm/aicha/registers/REGISTFF)))
do    
    line="${lines[0x$(cat /dev/shm/aicha/registers/REGISTFF)]}"
    
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
                                cat "/dev/shm/aicha/registers/$rvalue" > "/dev/shm/aicha/registers/$lvalue"
                            fi;;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                            echo "$rvalue" > "/dev/shm/aicha/registers/$lvalue";;
                     esac;;
                * )  
                     echo "ERR: MOV lvalue cannot be a number"
                     exit 2;;
            esac;;         
        "SHL" )
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )
                     T=$((0x$(cat "/dev/shm/aicha/registers/$lvalue")))
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )                     
                             T=$(($T << $((0x$(cat "/dev/shm/aicha/registers/$rvalue"))) & 0xFFFFFFFF));;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                             T=$(($T << $((0x$rvalue)) & 0xFFFFFFFF));;
                     esac
                     printf %08X $T > "/dev/shm/aicha/registers/$lvalue";;
                * )   
                     echo "ERR: SHL lvalue cannot be a number"
                     exit 2;; 
            esac;;
        "SHR" )
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )
                     T=$((0x$(cat "/dev/shm/aicha/registers/$lvalue")))
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )                     
                             T=$(($T >> $((0x$(cat "/dev/shm/aicha/registers/$rvalue")))));;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                             T=$(($T >> $((0x$rvalue))));;
                     esac
                     printf %08X $T > "/dev/shm/aicha/registers/$lvalue";;
                * )   
                     echo "ERR: SHR lvalue cannot be a number"
                     exit 2;; 
            esac;;
        "NOR" )
            case "$lvalue" in
                "REGIST"[0-9A-F][0-9A-F] )                
                     T=$((0x$(cat "/dev/shm/aicha/registers/$lvalue")))
                     case "$rvalue" in
                         "REGIST"[0-9A-F][0-9A-F] )                     
                             T=$(($((~$(($T | $((0x$(cat "/dev/shm/aicha/registers/$rvalue"))))))) & 0xFFFFFFFF));;
                         [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )
                             T=$((~$(($(($T | $((0x$rvalue)))))) & 0xFFFFFFFF));;
                     esac
                     printf %08X $T > "/dev/shm/aicha/registers/$lvalue";;
                * )   
                     echo "ERR: NOR lvalue cannot be a number"
                     exit 2;;  
            esac;;
        "NOP" ) ;;        
        [A-Z][0-9A-Z][0-9A-Z] )        
            if [ -n $lvalue ]
            then
                case "$lvalue" in
                    "REGIST"[0-9A-F][0-9A-F] )
                        if [ "$lvalue" != "$REGISTLEFT" ] 
                        then                    
                            cat "/dev/shm/aicha/registers/$lvalue" > "/dev/shm/aicha/registers/$REGISTLEFT"  
                        fi;;
                    [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] )                 
                        echo "$lvalue" > "/dev/shm/aicha/registers/$REGISTLEFT";;
                esac
            fi
            if [ -n $rvalue ]
            then 
                case "$rvalue" in
                    "REGIST"[0-9A-F][0-9A-F] )
                        if [ "$rvalue" != "$REGISTRGHT" ] 
                        then                         
                            cat "/dev/shm/aicha/registers/$rvalue" > "/dev/shm/aicha/registers/$REGISTRGHT"
                        fi;;
                    [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] ) 
                        echo "$rvalue" > "/dev/shm/aicha/registers/$REGISTRGHT";;
                esac
            fi
        
            if [ -n "$(find ./sys/ -name $command.aic | tr -d '\n')" ]
            then                
                OLDCARET=$((0x$(cat /dev/shm/aicha/registers/REGISTFF)))
                echo "00000000" > /dev/shm/aicha/registers/REGISTFF
                ./main.sh "$(find ./sys/ -name $command.aic | tr -d '\n')" $FORMAT "NO" "NO" $DEBUG_MODE $(($DEEPNESS + 1))
                printf %08X "$OLDCARET" > "/dev/shm/aicha/registers/REGISTFF"
            elif [ -n "$(find ./usr/ -name $command.aic | tr -d '\n')" ]
            then
                OLDCARET=$((0x$(cat /dev/shm/aicha/registers/REGISTFF)))
                echo "00000000" > /dev/shm/aicha/registers/REGISTFF
                ./main.sh "$(find ./usr/ -name $command.aic | tr -d '\n')" $FORMAT "NO" "NO" $DEBUG_MODE $(($DEEPNESS + 1))
                printf %08X "$OLDCARET" > "/dev/shm/aicha/registers/REGISTFF"
            else
                echo "ERR: Command \"$command\" is not found"
                exit 2;
            fi;;
        "#" ) 
        if [ "$DEBUG_MODE" == "DEBUG" ]
        then
            for ((i=0; i < "$DEEPNESS"; i++)) do echo -n "│"; done; echo "│ $line"
        fi;;
        "##" ) ;;
        "" ) ;;
        * )
            echo "ERR: Unknown command: \"$command\""
            exit 2;;
    esac
    
    TT=$((0x$(cat /dev/shm/aicha/registers/REGISTFF) + 1))
    printf %08X "$TT" > "/dev/shm/aicha/registers/REGISTFF"
done

for ((i=0; i < "$DEEPNESS"; i++)) do echo -n "│"; done; echo "└───"

if [ "$DEEPNESS" == 0 ]
then
    createOutput
    rm -f /dev/shm/aicha/registers/*
fi
