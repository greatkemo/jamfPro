#!/bin/bash

# Global variables
SCRIPT_NAME=$(basename "${0}")
HOST_NAME=$(hostname -s)

BD_TEAM_ID="GUNFMW623Y"
BD_SERVER_URL="$4" # Make sure to set this in jamf pro or change it to the server address
BD_DOWNLOAD_ID="$5"
BD_TEMP_DIRECTORY="$(mktemp -d "/private/tmp/$(uuidgen)_bd_downloader")"
BD_DOWNLOADER_DMG="setup_downloader.dmg"
BD_DOWNLOADER_URL="https://${BD_SERVER_URL}/Packages/MAC/0/${BD_DOWNLOAD_ID}/${BD_DOWNLOADER_DMG}"
BD_DMG_DOWNLOAD_PATH="${BD_TEMP_DIRECTORY}/${BD_DOWNLOADER_DMG}"
BD_MOUNT_POINT="/Volumes/Endpoint for MAC"
BD_DOWNLOADER_APP_PATH="${BD_MOUNT_POINT}/SetupDownloader.app/Contents/MacOS/SetupDownloader"

# Functions
function bd_log_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${HOST_NAME} ${SCRIPT_NAME}[$$]: ${1}" >> /Library/Logs/bitdefender_install.log
}

function bd_download_url_validation() {
    # this function will test that the authority server is up and reachable
    bd_log_cmd "Info: Checking if Bitdefender url is reachable"
    if curl -o /dev/null -sI --fail "${BD_DOWNLOADER_URL}"; then
        bd_log_cmd "Info: The url ${BD_DOWNLOADER_URL} is correct"
        return 0
    else
        bd_log_cmd "Error: The url ${BD_DOWNLOADER_URL} is incorrect"
        return 1
    fi
}

function bd_dmg_download() {
    # this function will use the download url to download the app from the bitdefender server
    bd_log_cmd "Info: Downloading ${BD_DOWNLOADER_DMG} from ${BD_DOWNLOADER_URL}"
    if curl -sk "${BD_DOWNLOADER_URL}" -o "${BD_DMG_DOWNLOAD_PATH}" --retry 3 && test -e "${BD_DMG_DOWNLOAD_PATH}"; then
        bd_log_cmd "Info: SetupDownload was downloaded to ${BD_DMG_DOWNLOAD_PATH}"
        return 0
    else
        bd_log_cmd "Error: ${BD_DOWNLOADER_DMG} download failed"
        return 1
    fi
}

function bd_mount_point_eject() {
    # make sure dmg is not still mounted from any previous attempt.
    bd_log_cmd "Info: Checking if dmg was previously mounted"
    while test -d "${BD_MOUNT_POINT}";  do
        bd_log_cmd "Info: Bitdefender volume was found, ejecting now" 
        hdiutil detach "${BD_MOUNT_POINT}" -force -quiet
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${BD_MOUNT_POINT}" ]]; then
        bd_log_cmd "Info: The dmg is not mounted"
        return 0
    else
        bd_log_cmd "Error: the dmg is still mounted"
        return 1
    fi
}

function bd_mount_downloader_dmg() {
    # mount the downloaded dmg disk image and verify it is mounted 
    bd_log_cmd "Info: Mounting Bitdefender dmg disk image"
    until hdiutil attach "${BD_DMG_DOWNLOAD_PATH}" -quiet -nobrowse; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -e "${BD_DOWNLOADER_APP_PATH}" ]]; then
        bd_log_cmd "Info: Bitdefender dmg was mounted correctly"
        return 0
    else
        bd_log_cmd "Error: Bitdefender dmg was not mounteded"
        return 1
    fi
}

function bd_verify_team_id() {
    
    # mount the downloaded dmg disk image and verify it is mounted 
    bd_log_cmd "Info: Mounting Bitdefender dmg disk image"
    if [[ $(codesign -dv "${BD_DOWNLOADER_APP_PATH}" 2>&1 | awk -F'=' '/TeamIdentifier/{print $2}') == "${BD_TEAM_ID}" ]]; then
        bd_log_cmd "Info: Bitdefender team id has been verified"
        
        return 0
    else
        bd_log_cmd "Error: Bitdefender team id has been was not verified"
        return 1
    fi
}

function bd_run_downloader_bin_silent() {
    # this function will install the bitdefender app using SetupDownloader.app
    bd_log_cmd "Info: Installing Bitdefender app, please check install.log for progress"
    until "${BD_DOWNLOADER_APP_PATH}" --silent >/dev/null 2>&1; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "/Library/Bitdefender/AVP/product/bin/EndpointSecurityforMac.app" ]]; then
        bd_log_cmd "Info: Bitdefender app was installed correctly"
        return 0
    else
        bd_log_cmd "Error: Bitdefender app was not installed"
        return 1
    fi
}

function bd_clean_up() {
    # eject the mounted volume and remove temporary files
    bd_log_cmd "Info: Ejecting Bitdefender volume"
    until bd_mount_point_eject; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    bd_log_cmd "Info: Removing Bitdefender temporary files"
    until rm -rf "${BD_TEMP_DIRECTORY}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${BD_TEMP_DIRECTORY}" ]]; then
        bd_log_cmd "Info: Bitdefender temporary files were removed correctly"
        return 0
    else
        bd_log_cmd "Error: Bitdefender temporary files were not removed correctly"
        return 1
    fi

}

function main() {
    # this is the main function to run and control all other functions
    bd_log_cmd "========== Bitdefender Installation Script Started =========="

    bd_log_cmd "Info: Starting function bd_download_url_validation"
    if bd_download_url_validation; then
        bd_log_cmd "Info: function bd_download_url_validation finished successfully"
    else
        bd_log_cmd "Error: function bd_download_url_validation failed"
        bd_clean_up
        exit 1
    fi
    
    bd_log_cmd "Info: Starting function bd_dmg_download"
    if bd_dmg_download; then
        bd_log_cmd "Info: function bd_dmg_download finished successfully"
    else
        bd_log_cmd "Error: function bd_dmg_download failed"
        bd_clean_up
        exit 1
    fi

    bd_log_cmd "Info: Starting function bd_mount_point_eject"
    if bd_mount_point_eject; then
        bd_log_cmd "Info: function bd_mount_point_eject finished successfully"
    else
        bd_log_cmd "Error: function bd_mount_point_eject failed"
        bd_clean_up
        exit 1
    fi
    
    bd_log_cmd "Info: Starting function bd_mount_downloader_dmg"
    if bd_mount_downloader_dmg; then
        bd_log_cmd "Info: function bd_mount_downloader_dmg finished successfully"
    else
        bd_log_cmd "Error: function bd_mount_downloader_dmg failed"
        bd_clean_up
        exit 1
    fi

    bd_log_cmd "Info: Starting function bd_verify_team_id"
    if bd_verify_team_id; then
        bd_log_cmd "Info: function bd_verify_team_id finished successfully"
    else
        bd_log_cmd "Error: function bd_verify_team_id failed"
        bd_clean_up
        exit 1
    fi

    bd_log_cmd "Info: Starting function bd_run_downloader_bin_silent"
    if bd_run_downloader_bin_silent; then
        bd_log_cmd "Info: function bd_run_downloader_bin_silent finished successfully"
    else
        bd_log_cmd "Error: function bd_run_downloader_bin_silent failed"
        bd_clean_up
        exit 1
    fi

    bd_log_cmd "Info: Starting function bd_clean_up"
    if bd_clean_up; then
        bd_log_cmd "Info: function bd_clean_up finished successfully"
    else
        bd_log_cmd "Error: function bd_clean_up failed"
        exit 1
    fi
    bd_log_cmd "========== Bitdefender Installation Script Ended =========="

}

main
