#!/bin/bash
if [ $# -lt 2 ]
then
    echo -e usage: "$0 <action> <text> <filename>\n actions: edit-comment, edit-tags"
    exit -1
fi

action=$1

if [ "$action" == "edit-comment" ]
then
    if [ $# == 2 ]; then
        exiv2 -M"del Exif.Photo.UserComment" $2
    elif [ $# == 3 ]; then
        new_comment=$2
        file=$3
        comment=$(exiv2 -Pt -g Exif.Photo.UserComment $file)
        if [[ $comment != $new_comment ]]; then
            exiv2 -M"set Exif.Photo.UserComment $new_comment" $file
        else
            exiv2 -M"del Exif.Photo.UserComment" $file
        fi
    fi
fi

if [ "$action" == "show" ]
then
    file=$2
    comment=$(exiv2 -Pt -g Exif.Photo.UserComment $file)
    exiv2 -Pt -g Iptc.Application2.Keywords $file > /tmp/._image_keywords.txt
    echo -n Comment: $comment, "Keywords: "
    first=true
    while read keyword
    do
        if [ $first == "false" ]
        then
            echo -n ", "
        fi
        echo -n $keyword
        first="false"
    done < /tmp/._image_keywords.txt
    echo
    rm /tmp/._image_keywords.txt
fi
