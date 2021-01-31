#!/bin/bash

script_name=$(basename "${0}")
host_name=$(hostname -s)
zoom_download_url=$(curl -si "https://zoom.us/client/latest/ZoomInstallerIT.pkg" | grep -i "location:" | awk '{print $2}')
zoom_pkg_name="zoom_us.pkg"
zoom_tmp_dir=$(mktemp -d "/private/tmp/zoom_$(uuidgen)")

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${host_name} ${script_name}[$$]: ${1}" >> /Library/Logs/zoom_install.log
}

function check_zoom_url() {
    # this function will test the zoom download url to see if it working
    logger_cmd "Validating zoom download url"
    if curl -o /dev/null -sI --fail "${zoom_download_url}"; then
        logger_cmd "INFO: The url ${zoom_download_url} is correct"
        return 0
    else
        logger_cmd "ERROR: The url ${zoom_download_url} is incorrect"
        return 1
    fi
}

function download_zoom_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Downloading ${zoom_pkg_name} from ${zoom_download_url}"
    if curl -Lso "${zoom_tmp_dir}/${zoom_pkg_name}" "${zoom_download_url}" --retry 3; then
        logger_cmd "INFO: ${zoom_pkg_name} was download to ${zoom_tmp_dir}"
        zoom_pkg_path="${zoom_tmp_dir}/${zoom_pkg_name}"
        return 0
    else
        logger_cmd "ERROR: ${zoom_pkg_name} download failed"
        return 1
    fi
}

function run_zoom_installer() {
    # this function will install the zoom app using macOS installer command
    logger_cmd "INFO: Installing Zoom app, check /var/log/install.log for progress"
    until installer -pkg "${zoom_pkg_path}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Applications/zoom.us.app" ]]; then
        logger_cmd "INFO: Zoom app was installed correctly"
        return 0
    else
        logger_cmd "ERROR: Zoom app was not installed"
        return 1
    fi
}

function install_zoom_audio_device() {
    # this function install the zoom audio device for sharing audio
    if [[ -d "/Library/Audio/Plug-Ins/HAL/ZoomAudioDevice.driver" ]]; then
        logger_cmd "INFO: Zoom Audio Device Already installed"
        return 0
    else
        logger_cmd "INFO: Zoom Audio Device not installed"
        logger_cmd "INFO: Installing Zoom Audio Device"
        until cp -R "/Applications/zoom.us.app/Contents/PlugIns/ZoomAudioDevice.driver" "/Library/Audio/Plug-Ins/HAL/"; do
            ((c++)) && ((c==5)) && break
            sleep 1
        done
        if [[ -d "/Library/Audio/Plug-Ins/HAL/ZoomAudioDevice.driver" ]]; then
            logger_cmd "INFO: Zoom Audio Device was installed successfully"
            logger_cmd "INFO: Restarting Core Audio Daemon"
            until killall coreaudiod; do
                ((c++)) && ((c==5)) && break
                sleep 1
            done
        else
            logger_cmd "ERROR: Zoom Audio Device was not installed"
            return 1
        fi
    fi

}

function clean_up() {
    # remove temporary files
    logger_cmd "INFO: Removing temporary files"
    until rm -rf "${zoom_tmp_dir}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${zoom_tmp_dir}" ]]; then
        logger_cmd "INFO: Zoom temporary files were removed correctly"
        return 0
    else
        logger_cmd "ERROR: Zoom temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "========== zoom.us Installation Script Started =========="
    logger_cmd "INFO: Starting function check_zoom_url"
    if check_zoom_url; then
        logger_cmd "INFO: function check_zoom_url finished successfully"
    else
        logger_cmd "ERROR: function check_zoom_url failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function download_zoom_pkg"
    if download_zoom_pkg; then
        logger_cmd "INFO: function download_zoom_pkg finished successfully"
    else
        logger_cmd "ERROR: function download_zoom_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function run_zoom_installer"
    if run_zoom_installer; then
        logger_cmd "INFO: function run_zoom_installer finished successfully"
    else
        logger_cmd "ERROR: function run_zoom_installer failed"
        clean_up
        exit 1
    fi

    logger_cmd "INFO: Starting function install_zoom_audio_device"
    if install_zoom_audio_device; then
        logger_cmd "INFO: function install_zoom_audio_device finished successfully"
    else
        logger_cmd "ERROR: function install_zoom_audio_device failed"
    fi
    
    logger_cmd "========== zoom.us Installation Script Ended =========="

    logger_cmd "INFO: Starting function clean_up"
    if clean_up; then
        logger_cmd "INFO: function clean_up finished successfully"
    else
        logger_cmd "ERROR: function clean_up failed"
        exit 1
    fi
}

main
