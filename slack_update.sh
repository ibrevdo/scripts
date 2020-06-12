#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

last_time=$(date -r /var/lib/slackpkg/ChangeLog.txt '+%m-%d-%Y %H:%M')

slackpkg update

read -p "Read ChangesLog.txt? (Previous ChangesLog is from $last_time) (y/N) " choice
if [[ $choice == "y" ]]; then
    vim /var/lib/slackpkg/ChangeLog.txt
fi

read -p "Continue with update? (y/N) " choice
if [[ $choice == "y" ]]; then
    slackpkg install-new
    slackpkg upgrade-all
else
    exit
fi
