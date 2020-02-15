#! /bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

LIST=$(find /etc -type f -name '*.new' -print | sed 's/\.new//')

for f in $LIST; do
    echo $f
    vim -d $f $f.new
    read -p  "The file $f is: Merged?(m) Overright?(o) Keep?(k) Quit?(q) " yn
    case $yn in
        "m" ) rm $f.new;;
        "o" ) mv $f.new $f;;
        "k" ) :;;
        "q" ) exit;;
    esac
done
