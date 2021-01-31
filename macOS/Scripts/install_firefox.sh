#!/bin/bash

script_name=$(basename "${0}")
host_name=$(hostname -s)
firefox_download_url=$(curl -si "https://download.mozilla.org/?product=firefox-pkg-latest-ssl&os=osx&lang=en-US" | grep -i "location:" | awk '{print $2}'| tr -d '\r')
firefox_pkg_name="Mozilla_Firefox.pkg"
firefox_tmp_dir=$(mktemp -d "/private/tmp/firefox_$(uuidgen)")

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${host_name} ${script_name}[$$]: ${1}" >> /Library/Logs/firefox_install.log
}

function check_firefox_url() {
    # this function will test the firefox download url to see if it working
    logger_cmd "Validating firefox download url"
    if curl -o /dev/null -sI --fail "${firefox_download_url}"; then
        logger_cmd "INFO: The url ${firefox_download_url} is correct"
        return 0
    else
        logger_cmd "ERROR: The url ${firefox_download_url} is incorrect"
        return 1
    fi
}

function download_firefox_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Downloading ${firefox_pkg_name} from ${firefox_download_url}"
    if curl -Lso "${firefox_tmp_dir}/${firefox_pkg_name}" "${firefox_download_url}" --retry 3; then
        logger_cmd "INFO: ${firefox_pkg_name} was download to ${firefox_tmp_dir}"
        firefox_pkg_path="${firefox_tmp_dir}/${firefox_pkg_name}"
        return 0
    else
        logger_cmd "ERROR: ${firefox_pkg_name} download failed"
        return 1
    fi
}

function run_firefox_installer() {
    # this function will install the firefox app using macOS installer command
    logger_cmd "INFO: Installing Mozilla Firefox, check /var/log/install.log for progress"
    until installer -pkg "${firefox_pkg_path}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Applications/Firefox.app" ]]; then
        logger_cmd "INFO: Mozilla Firefox was installed correctly"
        return 0
    else
        logger_cmd "ERROR: Mozilla Firefox was not installed"
        return 1
    fi
}

function clean_up() {
    # remove temporary files
    logger_cmd "INFO: Removing Mozilla Firefox temporary files"
    until rm -rf "${firefox_tmp_dir}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${firefox_tmp_dir}" ]]; then
        logger_cmd "INFO: Mozilla Firefox temporary files were removed correctly"
        return 0
    else
        logger_cmd "ERROR: Mozilla Firefox temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "========== Mozilla Firefox Installation Script Started =========="
    logger_cmd "INFO: Starting function check_firefox_url"
    if check_firefox_url; then
        logger_cmd "INFO: function check_firefox_url finished successfully"
    else
        logger_cmd "ERROR: function check_firefox_url failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function download_firefox_pkg"
    if download_firefox_pkg; then
        logger_cmd "INFO: function download_firefox_pkg finished successfully"
    else
        logger_cmd "ERROR: function download_firefox_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function run_firefox_installer"
    if run_firefox_installer; then
        logger_cmd "INFO: function run_firefox_installer finished successfully"
    else
        logger_cmd "ERROR: function run_firefox_installer failed"
        clean_up
        exit 1
    fi
    
    logger_cmd "========== Mozilla Firefox Installation Script Ended =========="

    logger_cmd "INFO: Starting function clean_up"
    if clean_up; then
        logger_cmd "INFO: function clean_up finished successfully"
    else
        logger_cmd "ERROR: function clean_up failed"
        exit 1
    fi
}

main
