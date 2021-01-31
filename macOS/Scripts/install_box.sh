#!/bin/bash

script_name=$(basename "${0}")
host_name=$(hostname -s)
box_download_url="https://e3.boxcdn.net/box-installers/desktop/releases/mac/Box.pkg"
box_pkg_name="Box.pkg"
box_tmp_dir=$(mktemp -d "/private/tmp/box_$(uuidgen)")

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${host_name} ${script_name}[$$]: ${1}" >> /Library/Logs/box_install.log
}

function check_box_url() {
    # this function will test the box download url to see if it working
    logger_cmd "Validating box download url"
    if curl -o /dev/null -sI --fail "${box_download_url}"; then
        logger_cmd "INFO: The url ${box_download_url} is correct"
        return 0
    else
        logger_cmd "ERROR: The url ${box_download_url} is incorrect"
        return 1
    fi
}

function download_box_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Downloading ${box_pkg_name} from ${box_download_url}"
    if curl -Lso "${box_tmp_dir}/${box_pkg_name}" "${box_download_url}" --retry 3; then
        logger_cmd "INFO: ${box_pkg_name} was download to ${box_tmp_dir}"
        box_pkg_path="${box_tmp_dir}/${box_pkg_name}"
        return 0
    else
        logger_cmd "ERROR: ${box_pkg_name} download failed"
        return 1
    fi
}

function run_box_installer() {
    # this function will install the box app using macOS installer command
    logger_cmd "INFO: Installing Box app, check /var/log/install.log for progress"
    until installer -pkg "${box_pkg_path}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Applications/Box.app" ]]; then
        logger_cmd "INFO: Box app was installed correctly"
        return 0
    else
        logger_cmd "ERROR: Box app was not installed"
        return 1
    fi
}

function clean_up() {
    # remove temporary files
    logger_cmd "INFO: Removing temporary files"
    until rm -rf "${box_tmp_dir}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${box_tmp_dir}" ]]; then
        logger_cmd "INFO: Box temporary files were removed correctly"
        return 0
    else
        logger_cmd "ERROR: Box temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "========== Box Installation Script Started =========="
    logger_cmd "INFO: Starting function check_box_url"
    if check_box_url; then
        logger_cmd "INFO: function check_box_url finished successfully"
    else
        logger_cmd "ERROR: function check_box_url failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function download_box_pkg"
    if download_box_pkg; then
        logger_cmd "INFO: function download_box_pkg finished successfully"
    else
        logger_cmd "ERROR: function download_box_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function run_box_installer"
    if run_box_installer; then
        logger_cmd "INFO: function run_box_installer finished successfully"
    else
        logger_cmd "ERROR: function run_box_installer failed"
        clean_up
        exit 1
    fi
    
    logger_cmd "========== Box Installation Script Ended =========="

    logger_cmd "INFO: Starting function clean_up"
    if clean_up; then
        logger_cmd "INFO: function clean_up finished successfully"
    else
        logger_cmd "ERROR: function clean_up failed"
        exit 1
    fi
}

main
