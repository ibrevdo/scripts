#!/bin/bash

# This script should install slackware package downloaded from slackbuilds site

# the local copy of slackbuilds.org repository
slackbuilds_repo='/home/mago/installs/slackbuilds/'


function usage() {
    echo 'Usage:'
    echo -e '\t' `echo $0 | sed 's/.*\///'` 'list     ' '\t\t' 'list installed slackbuild packages'
    echo -e '\t' `echo $0 | sed 's/.*\///'` 'status   [package]' '\t' 'show package info and status'
    echo -e '\t' `echo $0 | sed 's/.*\///'` 'install  [package]' '\t' 'download, build and install package'
    exit
}


# This function lists all slackbuilds packages currently installed 
# and checks whether they should be upgraded

function list_installed_pkgs_status() {

    local GREEN
    local RED
    local NORMAL
    local package
    local packages
    local current_version
    local new_version
    local package_info

    GREEN=$(tput setaf 2)
    RED=$(tput setaf 5)
    normal=$(tput sgr0)

    # a list of currenlty installed slackbuilds packages
    packages=($(ls -1 /var/log/packages | grep SBo))

    for p in "${packages[@]}"; do
        printf "%-50s" $p

        # get the name of the package. the name should be from start till "-digit"
        # so [0-9.].* means: at least one digit or dot, followed by anything till end of line
        # the following command filters out (deletes) everything after '-' and digits
        package=`echo $p | sed 's/-[0-9.].*//'`
        
        # installed version. the version number goes after '-' and consists of digits and dots 
        # and till '-' followed by x (x64..) or n (noarch).
        # the following filters out everything exept the version number iteslf
        current_version=`echo $p | sed 's/.*-\([0-9.].*\)-[xn].*/\1/'`

        package_info=`find $slackbuilds_repo -name  "$package.info" `
        if [[ -n $package_info ]] ; then
            # the updated version. in file .info, find the line VERSION=..
            # and filter out the version number of updated package in similar way as before
            new_version=($(grep VERSION $package_info | sed 's/.*="\([0-9.].*\)"/\1/'))
            
            if [[ $current_version != $new_version ]] ; then
                printf "%s%-30s %s -> %s%s\n" ${GREEN} $package $current_version $new_version ${normal}
            else
                printf "%-30s is up-to-date\n" $package
            fi
        else
            printf "%s%-30s was not found!%s\n" ${RED} $package ${normal} 
        fi
    done
}


function parse_pkg_info() {
    
    local path_to_packages
    path_to_packages=($(find $slackbuilds_repo -type d -iname "$1*"))
    if [[ ${#path_to_packages[@]} > 1 ]] ; then 
        for p in "${path_to_packages[@]}"; do
            # show category and a package only (two last dirs from the full path
            echo `echo $p | sed 's/.*\/\([a-z].*\/.*\)/\1/'`
        done
        read -p "Found ${#path_to_packages[@]} packages. Choose exact name (name only): " choice
        for p in "${path_to_packages[@]}"; do
            if [[ $choice == `echo $p | sed 's/.*\///'` ]] ; then
                PKG_NAME=$choice
                cd $p
            fi
        done
    elif [[ ${#path_to_packages[@]} == 1 ]] ; then
        # show category and a package only (two last dirs from the full path
        PKG_FULL_NAME=`echo $path_to_packages | sed 's/.*\/\([a-z].*\/.*\)/\1/'`
        PKG_NAME=`echo ${path_to_packages[0]} | sed 's/.*\///'`
        cd ${path_to_packages[0]}
    else
        echo "Couldn't find package '$1'" && exit
    fi

    #source package info file
    source ${PKG_NAME}.info
    
}

function show_pkg_status() {
    local installed_packages
    local ready
    local installed_version
    local status

    # installed packages
    installed_packages=($(ls -1 /var/log/packages ))

    # check for dependencies
    #deps=`grep REQUIRES ${PKG_NAME}.info | sed 's/.*="\(.*\)"/\1/'`
    ready="ready"

    echo
    echo Package description: ${PKG_NAME} \( ver $VERSION \)
    echo --------------------------------------------------------------------
    cat README
    echo --------------------------------------------------------------------
    echo
    
    printf "Dependencies\n--------------------------------------------------------------------\n"
    for d in ${REQUIRES[@]}; do
        status="missing"
        
        for p in ${installed_packages[@]}; do
            if [[ $p =~ ^$d-.*$ ]]; then
                status="installed"
            fi
        done
        printf "%-20s is %s\n" $d $status
        if [[ $status = "missing" ]]; then ready="not ready"; fi
    done

    # check if already installed
    for p in ${installed_packages[@]}; do
        if [[ $p = $PKG_NAME* ]]; then
            installed_version=`echo $p | sed 's/.*-\([0-9.].*\)-[xn].*/\1/'`
            break
        fi
    done

    printf "\nStatus\n--------------------------------------------------------------------\n"
    if [[ -n $installed_version && $installed_version = $VERSION ]] ; then
        echo Package $PKG_NAME is already installed with latest version \( $p \)
        echo
        return
    fi

    if [[ $ready = "not ready" ]] ; then
        echo Package $PKG_NAME is not ready to be installed/updated
        [[ -n $installed_version ]] && echo Currently installed version $installed_version
        echo
        return
    fi

    if [[ -n $installed_version ]]; then
        echo Package $PKG_NAME can be updated from version $installed_version to version $VERSION
    else
        echo Package $PKG_NAME is ready to be installed
    fi
    echo
}



function install_pkg() {

    local SLACK_PKG

    cat ${PKG_NAME}.info
    read -p "Download package? (y/N) " choice
    if [[ $choice = "y" ]]; then
        if [[ -n ${DOWNLOAD_x86_64} ]]; then
            for d in ${DOWNLOAD_x86_64}; do wget $d; done
        else
            for d in ${DOWNLOAD}; do wget $d; done
        fi
        echo "----------------------------------------------------------------"
    fi

    read -p "Build package? (y/N) " choice
    if [[ $choice = "y" ]]; then
        sudo -E bash ${PKG_NAME}.SlackBuild | tee out
        SLACK_PKG=`grep 'Slackware.*created' out | awk '{print $3}'`
        rm out
        echo "----------------------------------------------------------------"
    fi

    read -p "Install package? (y/N) " choice
    if [[ $choice = "y" ]]; then
        sudo upgradepkg --install-new $SLACK_PKG
    fi
}


if [ -n "$1" ]; then
    CMD=$1
    shift
    case "$CMD" in 
        list)
            list_installed_pkgs_status
            ;;
        status)
            if [ -n "$1" ]; then
                printf "\nOfficial repositories status
-----------------------------------------------------------\n"
                slackpkg search $1 | grep --color "^ *\(uninstalled\|installed\)"
                status="$(slackpkg search $1 | grep --color "^ *\(uninstalled\|installed\)")"
                if [ -z "$status" ]; then
                    printf "None\n\n"
                else
                    read -p "Continue looking for package? (y/N) " choice
                    if [[ $choice != "y" ]]; then
                        exit
                    fi
                fi
                parse_pkg_info "$1"
                show_pkg_status
            else
                usage
            fi
            ;;
        install)
            if [ -n "$1" ]; then
                parse_pkg_info "$1"
                install_pkg 
            else
                usage
            fi
            ;;
        *)
            usage
            ;;
    esac
else
    usage
fi
