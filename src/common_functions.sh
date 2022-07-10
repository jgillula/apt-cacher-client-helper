#!/bin/bash

PROXY_SERVER_NOT_SET_STRING="not set"
VERSION="0.0.0"

get_apt_config () {
    local apt_config_output=$1
    local config_key=$2
    local pattern="$config_key\s+\\\"([^\\\"]+)\\\";"
    
    echo "$(echo -e "$apt_config_output" | grep -E "$pattern" | sed -E "s/$pattern/\1/")"
}

regex_escape () {
    echo "$(echo "$1" | sed 's/[^-A-Za-z0-9_]/\\&/g')"
}

initialize_variables () {
    # Automatically figure out where all the *.list files are from apt's own config
    APT_CONFIG_OUTPUT=$(apt-config dump)
    dir_etc=$(get_apt_config "$APT_CONFIG_OUTPUT" "Dir::Etc")
    sourcelist=$(get_apt_config "$APT_CONFIG_OUTPUT" "Dir::Etc::sourcelist")
    sourceparts=$(get_apt_config "$APT_CONFIG_OUTPUT" "Dir::Etc::sourceparts")
    apt_config_parts_dir="/${dir_etc}/"$(get_apt_config "$APT_CONFIG_OUTPUT" "Dir::Etc::parts")
    apt_cacher_proxy_config_file="${apt_config_parts_dir}/02apt-cacher-proxy"
    apt_cacher_client_helper_https_fixer_config_file="${apt_config_parts_dir}/99https-repo-fixer"
    # We set this in case there are no files in what is probably /etc/apt/sources.list.d/
    shopt -s nullglob
    SOURCE_FILES=(/$dir_etc/$sourceparts/*.list)
    SOURCE_FILES+=(/"$dir_etc"/"$sourcelist")    
    comment_line="### This line commented out by apt-cacher-client-helper and replaced with the line below ### "
    comment_line=$(regex_escape "$comment_line")

    APT_CACHER_SERVER=$(get_apt_config "$APT_CONFIG_OUTPUT" "Acquire::http::proxy")
    if [ -z "$APT_CACHER_SERVER" ]; then
        APT_CACHER_SERVER="$PROXY_SERVER_NOT_SET_STRING"
    fi
    
    string_to_insert="http://HTTPS///"
    string_to_insert=$(regex_escape "$string_to_insert")

    columns=$(stty size | awk '{print $2}')
}

check_root () {
    # Check if the current user is root otherwise exit with an error
    [ "$(whoami)" != "root" ] && >&2 echo "Error: ${0##*/} must be run as root" && exit 2
}

check_apt_proxy_server () {
    if [ "$APT_CACHER_SERVER" == "$PROXY_SERVER_NOT_SET_STRING" ]; then
        echo "Error: apt is not configured to use a proxy server. To use an apt-cacher-server, see the instructions for configuring a proxy at https://www.unix-ag.uni-kl.de/~bloch/acng/html/config-servquick.html#config-client, or run ${0##*/} -e -a" | >&2 fold -s -w $columns -
        exit 3
    fi    
}
