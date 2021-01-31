#!/bin/bash

script_name=$(basename "${0}")
host_name=$(hostname -s)
chrome_download_url="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
chrome_pkg_name="googlechrome.pkg"
chrome_tmp_dir=$(mktemp -d "/private/tmp/chrome_$(uuidgen)")

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${host_name} ${script_name}[$$]: ${1}" >> /Library/Logs/chrome_install.log
}

function check_chrome_url() {
    # this function will test the chrome download url to see if it working
    logger_cmd "Validating chrome download url"
    if curl -o /dev/null -sI --fail "${chrome_download_url}"; then
        logger_cmd "INFO: The url ${chrome_download_url} is correct"
        return 0
    else
        logger_cmd "ERROR: The url ${chrome_download_url} is incorrect"
        return 1
    fi
}

function download_chrome_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Downloading ${chrome_pkg_name} from ${chrome_download_url}"
    if curl -Lso "${chrome_tmp_dir}/${chrome_pkg_name}" "${chrome_download_url}" --retry 3; then
        logger_cmd "INFO: ${chrome_pkg_name} was download to ${chrome_tmp_dir}"
        chrome_pkg_path="${chrome_tmp_dir}/${chrome_pkg_name}"
        return 0
    else
        logger_cmd "ERROR: ${chrome_pkg_name} download failed"
        return 1
    fi
}

function run_chrome_installer() {
    # this function will install the chrome app using macOS installer command
    logger_cmd "INFO: Installing Chrome app, check /var/log/install.log for progress"
    until installer -pkg "${chrome_pkg_path}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Applications/Google Chrome.app" ]]; then
        logger_cmd "INFO: Chrome app was installed correctly"
        return 0
    else
        logger_cmd "ERROR: Chrome app was not installed"
        return 1
    fi
}

function clean_up() {
    # remove temporary files
    logger_cmd "INFO: Removing temporary files"
    until rm -rf "${chrome_tmp_dir}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${chrome_tmp_dir}" ]]; then
        logger_cmd "INFO: Chrome temporary files were removed correctly"
        return 0
    else
        logger_cmd "ERROR: Chrome temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "========== Google Chrome Installation Script Started =========="
    logger_cmd "INFO: Starting function check_chrome_url"
    if check_chrome_url; then
        logger_cmd "INFO: function check_chrome_url finished successfully"
    else
        logger_cmd "ERROR: function check_chrome_url failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function download_chrome_pkg"
    if download_chrome_pkg; then
        logger_cmd "INFO: function download_chrome_pkg finished successfully"
    else
        logger_cmd "ERROR: function download_chrome_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function run_chrome_installer"
    if run_chrome_installer; then
        logger_cmd "INFO: function run_chrome_installer finished successfully"
    else
        logger_cmd "ERROR: function run_chrome_installer failed"
        clean_up
        exit 1
    fi
    
    logger_cmd "========== Google Chrome Installation Script Ended =========="

    logger_cmd "INFO: Starting function clean_up"
    if clean_up; then
        logger_cmd "INFO: function clean_up finished successfully"
    else
        logger_cmd "ERROR: function clean_up failed"
        exit 1
    fi
}

main
