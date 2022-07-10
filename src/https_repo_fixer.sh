#!/bin/bash

APT_CACHER_CLIENT_HELPER_LIB_DIR="."
. "$APT_CACHER_CLIENT_HELPER_LIB_DIR"/common_functions.sh

show_usage() {
    echo "Usage: ${0##*/} [-m|-r|-h]"
}

show_help() {
    show_usage
    echo "Automatically detect your current apt-cacher server by reading apt's config to find the current proxy server ($APT_CACHER_SERVER), and then modify apt's .list files so all https repos pass through that server" | fold -s -w $columns -
    help_string=$(cat <<EOF
  -m, --modify|Automatically modify apt's .list files so all https repos pass through the current proxy server ($APT_CACHER_SERVER)
  -r, --revert|Revert changes to all .list files ${0##*/} would normally modify
  -h, --help|Show this help
EOF
               )
    echo "$help_string" | column -t -s '|' -c $columns
}

modify_list_files () {    
    check_apt_proxy_server
    
    deb_line_regex_pattern='^(([[:space:]]*(?:#+[[:space:]]+)?(?:deb|deb-src)[[:space:]]+(?:\[[^\[\]]+\][[:space:]]+)*)https:\/\/(.+))$'

    # Now for every *.list file
    for filename in "${SOURCE_FILES[@]}"; do
        perl -p -i -e "s/$deb_line_regex_pattern/$comment_line\1\n\2$string_to_insert\3/g" "$filename"
    done
}

revert_list_files () {  
    apt_cacher_line_regex_pattern="^([[:space:]]*(?:#+[[:space:]]+)?(?:deb|deb-src)[[:space:]]+(?:\[[^\[\]]+\][[:space:]]+)*)https?:\/\/HTTPS\/\/\/(.+)$"
    
    for filename in "${SOURCE_FILES[@]}"; do
        perl -n -i -e "s/^$comment_line//g;" -e "print unless m/$apt_cacher_line_regex_pattern/;" "$filename"
    done 
}

initialize_variables

options=`getopt -o hmr --long help,modify,revert -n "${0##*/}" -- "$@"`
if test $? -ne 0 ; then
    show_usage
    echo "Try '${0##*/} --help' for more information"
    exit 1
fi

eval set -- "$options"

while true ; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--modify)
            check_root
            modify_list_files
            exit 0
            ;;
        -r|--revert) 
            check_root
            revert_list_files
            exit 0
            ;;
        --) shift ; break ;;
        *) >&2 echo "Error: Problem parsing command-line arguments!" ; exit 1 ;;
    esac    
done

show_help
exit 0
