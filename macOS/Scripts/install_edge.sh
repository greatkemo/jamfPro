#!/bin/bash

script_name=$(basename "${0}")
host_name=$(hostname -s)
edge_download_url=$(curl -si "https://go.microsoft.com/fwlink/?linkid=2069148" | grep -i "location:" | awk '{print $2}')
edge_pkg_name="Microsoft_Edge.pkg"
edge_tmp_dir=$(mktemp -d "/private/tmp/edge_$(uuidgen)")

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${host_name} ${script_name}[$$]: ${1}" >> /Library/Logs/edge_install.log
}

function check_edge_url() {
    # this function will test the edge download url to see if it working
    logger_cmd "Validating edge download url"
    if curl -o /dev/null -sI --fail "${edge_download_url}"; then
        logger_cmd "INFO: The url ${edge_download_url} is correct"
        return 0
    else
        logger_cmd "ERROR: The url ${edge_download_url} is incorrect"
        return 1
    fi
}

function download_edge_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Downloading ${edge_pkg_name} from ${edge_download_url}"
    if curl -Lso "${edge_tmp_dir}/${edge_pkg_name}" "${edge_download_url}" --retry 3; then
        logger_cmd "INFO: ${edge_pkg_name} was download to ${edge_tmp_dir}"
        edge_pkg_path="${edge_tmp_dir}/${edge_pkg_name}"
        return 0
    else
        logger_cmd "ERROR: ${edge_pkg_name} download failed"
        return 1
    fi
}

function run_edge_installer() {
    # this function will install the edge app using macOS installer command
    logger_cmd "INFO: Installing Microsoft Edge, check /var/log/install.log for progress"
    until installer -pkg "${edge_pkg_path}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Applications/Microsoft Edge.app" ]]; then
        logger_cmd "INFO: Microsoft Edge was installed correctly"
        return 0
    else
        logger_cmd "ERROR: Microsoft Edge was not installed"
        return 1
    fi
}

function clean_up() {
    # remove temporary files
    logger_cmd "INFO: Removing temporary files"
    until rm -rf "${edge_tmp_dir}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${edge_tmp_dir}" ]]; then
        logger_cmd "INFO: Microsoft Edge temporary files were removed correctly"
        return 0
    else
        logger_cmd "ERROR: Microsoft Edge temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "========== Microsoft Edge Installation Script Started =========="
    logger_cmd "INFO: Starting function check_edge_url"
    if check_edge_url; then
        logger_cmd "INFO: function check_edge_url finished successfully"
    else
        logger_cmd "ERROR: function check_edge_url failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function download_edge_pkg"
    if download_edge_pkg; then
        logger_cmd "INFO: function download_edge_pkg finished successfully"
    else
        logger_cmd "ERROR: function download_edge_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function run_edge_installer"
    if run_edge_installer; then
        logger_cmd "INFO: function run_edge_installer finished successfully"
    else
        logger_cmd "ERROR: function run_edge_installer failed"
        clean_up
        exit 1
    fi
    
    logger_cmd "========== Microsoft Edge Installation Script Ended =========="

    logger_cmd "INFO: Starting function clean_up"
    if clean_up; then
        logger_cmd "INFO: function clean_up finished successfully"
    else
        logger_cmd "ERROR: function clean_up failed"
        exit 1
    fi
}

main
