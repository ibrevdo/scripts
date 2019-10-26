#!/bin/bash

for i in "$@"
do
    case $i in
        -c=*|--comment=*)
            COMMENT="${i#*=}"
            shift # past argument=value
            ;;
        -h|--help)
            echo -e usage: "$0 <options> <files>\n options: -c|--comment=[comment], -h|--help"
            exit -1
            ;;
        *)
            # no options
            ;;
    esac
done

params="$@"

if [ -z "$COMMENT" ] ; then
    echo "no comments"
    feh -d                                                      \
        --info "image-metadata.sh show %F" $params
else
    echo "comment: $COMMENT"
    feh -d                                                              \
        --action1 "image-metadata.sh edit-comment \"$COMMENT\" %F"     \
        --info "image-metadata.sh show %F" $params
fi
