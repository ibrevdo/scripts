#!/bin/bash

#
# Usage : fnconv.sh <JPG image files>
#
# Description:
# The script runs on it's argument list (list of image files) or takes it from standard input
# For every image file, the script checks whether the exif data contains creation date and camera model 
# and then updates the name of file accoring to this exif data.
# New filename form is (create date)_(camera model)_(keywords).jpg
# New files go to "out" subdirectory
#
# If no exif data is present and the file looks like it created by WhatsUp, then
# the script deduces these missing fields from the current file name.
# In this case, the script will also add these fileds in exif data of the file
#
# The script depends on exiv2 command

WA_DATE_FMT='s/IMG-([0-9]*)-.*/\1/g'
WA_END_FMT='s/.*-(.*)\.jpg/\1/g'
WA_DATE_FMT_OUT='+%Y:%m:%d'

SED_FMT='s/([0-9]*):([0-9]*):([0-9]*)\ (.*)/\1-\2-\3 \4/g'
DATE_FMT='+%Y:%m:%d %H:%M:%S'

print_usage(){
    printf "\n%s\t%s %s\n"  "Usage:" `basename "$0"` "<param> <list of image files> (or take them from stdin)"
    printf "%s\n"           "Description:" 
    printf "\t%s\n"           "Updates filename of image file according to EXIF creation time field."
    printf "\t%s\n"           "If no EXIF time field is present and filename is of WhatsUp pattern,"
    printf "\t%s\n"           "then creation time is deduced from the filename and updated in the file."
    printf "\t%s\n"           "Files should be JPG format."
    printf "%s\n"           "The <param> is optional parameter:"
    printf "\t%s %s\n"        `basename "$0"` "--shift=<shift in hours> (should be relative to IST)"
    printf "\t%s %s\n"        `basename "$0"` "--remcomment remove comment from files"       
    printf "\t%s %s\n"        `basename "$0"` "-h|--help    print this help"       
}

time_shift(){
    local photo=$1
    local exif_data="$(exiv2 $photo)"
    local original_date="$(echo "$exif_data" | grep -i "Image timestamp" | awk -F ": " '{print $2 }' | sed -r "${SED_FMT}")"
    local new_date=$(date --date="${original_date} IST${TIME_SHIFT}" "$DATE_FMT" 2>&1)
#    printf "%-30s -> %s\n" "$original_date" "$new_date"
    exiv2 -M"set Exif.Photo.DateTimeOriginal $new_date" $photo
    echo $new_date
}

remcomment(){
    local exif_data="$(exiv2 $1)"
    local comment="$(echo "$exif_data" | grep -i "Exif comment" | awk -F ': ' '{print $2}')"
    printf '%-30s: %s\n' $1 "$([ ! -z "$comment" ] && echo ${comment} || echo No comments)"
    exiv2 -M"set Exif.Photo.UserComment " $1
}

for i in "$@"
do
    case $i in 
        -h|--help)
            print_usage
            exit
            ;;
        --remcomment)
            REM_COMMENT="yes"
            shift
            ;;
        --shift=*)
            TIME_SHIFT="${i#*=}"
            TIME_SHIFT="$TIME_SHIFT hours"
            shift
            ;;
        *)
            #files list
            ;;
    esac
done


#check if there any arguments to a script
if [ $# -eq 0 ]; then
    # here the standard input for a grep command is inherited from standard input of the current script 
    # (ie. a list of filenames that I pass to this string from the command line)
    photos=($(grep -Ei ".jp(.?)g$" ))
else 
    photos=($(ls $@ | grep -Ei ".jp(.?)g$"))
fi

for photo in "${photos[@]}"; do
    p=$photo
    exif_data="$(exiv2 $p)"
    original_date="$(echo "$exif_data" | grep -i "Image timestamp" | awk -F ": " '{print $2 }' | sed s/://g | sed s/\ /-/g)"
    camera="$(echo "$exif_data" | grep -i "Camera model" | awk -F ': ' '{print $2}' | sed s/\ /_/g)"
    
    if [ -z "$original_date" ]; then
        if [[ $p == *"WA"* ]]; then
            new_date=$(date --date="$(echo $p | sed -r "${WA_DATE_FMT}")" $WA_DATE_FMT_OUT)
            # set Date/Time Original to exif data of a file
            exiv2 -M"set Exif.Photo.DateTimeOriginal $new_date" $p
            original_date="$(echo "$new_date" | sed s/://g)" 
        fi
    fi
    
    if ! [  -z "${TIME_SHIFT}" ]; then
        new_date=$(time_shift $p)
        if ! [[ $new_date == *"invalid"* ]]; then
            original_date="$(echo "$new_date" | sed s/://g | sed s/\ /-/g)" 
        else
            echo "$p: invalid date. time-tag not time-shifted"
        fi
    fi

    if [ -z "$camera" ]; then
        if [[ $p == *"WA"* ]]; then
            # set Camera model to exif data of a file
            camera="$(echo $p | sed -r "${WA_END_FMT}")"
            exiv2 -M"set Exif.Image.Model $camera"  $p
        fi
    fi
    
    if [[ $REM_COMMENT == *"yes"* ]]; then
        remcomment $p
    fi

    new_file="$(echo ${original_date}_${camera}).jpg"
    if [[ $p != $new_file ]]; then 
        printf '%-30s -> %s\n' "$p" "$new_file"
        mv $p $new_file
    else
        printf '%-30s\n' "$p" 
    fi
done
