#!/bin/bash

script_name=$(basename "${0}")
host_name=$(hostname -s)
office_download_url=$(curl -si "https://go.microsoft.com/fwlink/?linkid=2009112" | grep -i "location:" | awk '{print $2}' | tr -d '\r')
office_pkg_name="Microsoft_Office_BusinessPro_Installer.pkg"
office_tmp_dir=$(mktemp -d "/private/tmp/office_$(uuidgen)")

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${host_name} ${script_name}[$$]: ${1}" >> /Library/Logs/office_install.log
}

function check_office_url() {
    # this function will test the office download url to see if it working
    logger_cmd "Validating office download url"
    if curl -o /dev/null -sI --fail "${office_download_url}"; then
        logger_cmd "INFO: The url ${office_download_url} is correct"
        return 0
    else
        logger_cmd "ERROR: The url ${office_download_url} is incorrect"
        return 1
    fi
}

function download_office_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Downloading ${office_pkg_name} from ${office_download_url}"
    if curl -Lso "${office_tmp_dir}/${office_pkg_name}" "${office_download_url}" --retry 3; then
        logger_cmd "INFO: ${office_pkg_name} was download to ${office_tmp_dir}"
        office_pkg_path="${office_tmp_dir}/${office_pkg_name}"
        return 0
    else
        logger_cmd "ERROR: ${office_pkg_name} download failed"
        return 1
    fi
}

function run_office_installer() {
    # this function will install the office app using macOS installer command
    logger_cmd "INFO: Installing Microsoft Office, check /var/log/install.log for progress"
    until installer -pkg "${office_pkg_path}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Applications/Microsoft Word.app" ]] && [[ -d "/Applications/Microsoft Excel.app" ]] && [[ -d "/Applications/Microsoft PowerPoint.app" ]] && [[ -d "/Applications/Microsoft Outlook.app" ]]; then
        logger_cmd "INFO: Microsoft Office was installed correctly"
        return 0
    else
        logger_cmd "ERROR: Microsoft Office was not installed"
        return 1
    fi
}

function clean_up() {
    # remove temporary files
    logger_cmd "INFO: Removing temporary files"
    until rm -rf "${office_tmp_dir}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${office_tmp_dir}" ]]; then
        logger_cmd "INFO: Microsoft Office temporary files were removed correctly"
        return 0
    else
        logger_cmd "ERROR: Microsoft Office temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "========== Microsoft Office Installation Script Started =========="
    logger_cmd "INFO: Starting function check_office_url"
    if check_office_url; then
        logger_cmd "INFO: function check_office_url finished successfully"
    else
        logger_cmd "ERROR: function check_office_url failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function download_office_pkg"
    if download_office_pkg; then
        logger_cmd "INFO: function download_office_pkg finished successfully"
    else
        logger_cmd "ERROR: function download_office_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function run_office_installer"
    if run_office_installer; then
        logger_cmd "INFO: function run_office_installer finished successfully"
    else
        logger_cmd "ERROR: function run_office_installer failed"
        clean_up
        exit 1
    fi
    
    logger_cmd "========== Microsoft Office Installation Script Ended =========="

    logger_cmd "INFO: Starting function clean_up"
    if clean_up; then
        logger_cmd "INFO: function clean_up finished successfully"
    else
        logger_cmd "ERROR: function clean_up failed"
        exit 1
    fi
}

main
