#!/bin/bash

USAGE="$(basename $0 .sh) <filename.md>"
COMMAND=grip 

if [ ! $# -eq 1 ]; then
    echo $USAGE
    exit;
fi

if [ ! -f $1 ]; then
    echo "$1 : The file doesn't exist"
    exit;
elif [ ! ${1: -3} == ".md" ]; then
    echo "$(basename $1) : Warning: The file should have .md extension"
    exit;
elif [ $(basename $1 .md) == "notes" ]; then
    PARAMS="$1 localhost:6420"
elif [ $(basename $1 .md) == "bookmarks" ]; then
    PARAMS="$1 localhost:6421"
else
    PARAMS="$1"
fi


SESSION_NAME="${COMMAND}_$(basename $1 .md)_session"
SCREEN_COMMAND="screen -d -S $SESSION_NAME -m $COMMAND $PARAMS"

if [[ `screen -ls` == *$SESSION_NAME* ]]; then 
    echo "screen session $SESSION_NAME exists"; 
    if [[ `screen -ls | grep $COMMAND | grep Dead` ]]; then
        echo '..but appears to be dead. restarting new screen.';        
        echo "$SCREEN_COMMAND";
        screen -wipe
        $SCREEN_COMMAND
    fi
else
    echo "starting : $SCREEN_COMMAND";        
    $SCREEN_COMMAND
fi
