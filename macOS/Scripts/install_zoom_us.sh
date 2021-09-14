#!/bin/bash

#
#
# This script can be used to install the latest version of Zoom on macOS.
#
# This can also update zoom, by checking for the latest version of zoom on online
# then comparing it with with installed version and performs an update procedure if
# the installed version is outdated.  This script also leverages the use of jamfHelper
# for user interaction.
#
# Author: Kamal Taynaz
# Date last updated: Sep, 14 2021 
#
#

# Global variable, does require any editing.
SCRIPT_NAME=$(basename "${0}")
HOST_NAME=$(hostname -s)
MACOS_VERSION=$(sw_vers -productVersion | sed 's/[.]/_/g')
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X ${MACOS_VERSION}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"
USER_IDLE_TIME=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
ZOOM_TMP_DIRECTORY=$(mktemp -d "/private/tmp/$(uuidgen)_zoom.us")
ZOOM_APP_PATH="/Applications/zoom.us.app"
ZOOM_ICON_PATH="${ZOOM_APP_PATH}/Contents/Resources/ZPLogo.icns"
ZOOM_PKG_NAME="ZoomInstallerIT.pkg"
ZOOM_PKG_PATH="${ZOOM_TMP_DIRECTORY}/${ZOOM_PKG_NAME}"
ZOOM_DOWNLOAD_URL=$(curl -si "https://zoom.us/client/latest/${ZOOM_PKG_NAME}" | grep -i "location:" | awk '{print $2}' | tr -d '\r')
ZOOM_LATEST_VERSION=$(curl -s -A "${USER_AGENT}" https://zoom.us/download | grep 'ZoomInstallerIT.pkg' | awk -F'/' '{print $3}')
ZOOM_INSTALLED_VERSION=$(defaults read ${ZOOM_APP_PATH}/Contents/Info CFBundleVersion 2>/dev/null | sed -e 's/0 //g' -e 's/(//g' -e 's/)//g')

function logger_cmd() {
    # this function will provide the feedback from the script for debugging.
    echo "${1}"
    echo "$(date "+%b %d %H:%M:%S") ${HOST_NAME} ${SCRIPT_NAME}[$$]: ${1}" >> /Library/Logs/zoom_install.log
}

function jamfhelper_zoom_update() {
    # this function enabled a user prompt to update or defer.
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" \
    -windowType "utility" \
    -title "Update Available" \
    -heading "Zoom ${ZOOM_LATEST_VERSION} is available" \
    -alignHeading "natural" \
    -description "$(printf "Click 'Update' to install the new version or 'Defer' to postpone.  \n\nThe process will only take a few of minutes to complete. No restart is required.")" \
    -alignDescription "natural" \
    -icon "${ZOOM_ICON_PATH}" \
    -button1 "Update" \
    -button2 "Defer" \
    -defaultButton "1" \
    -cancelButton "2" \
    -timeout "120" \
    -countdown \
    -countdownPrompt "Will autoupdate in: " \
    -alignCountdown "right" \
    -lockHUD >/dev/null
}

function is_zoom_up_to_date() {
    # this function will test if zoom is up to date or not.
    logger_cmd "Info: Latest version: ${ZOOM_LATEST_VERSION}"
	logger_cmd "Info: Installed version: ${ZOOM_INSTALLED_VERSION}"
	if [[ "${ZOOM_LATEST_VERSION}" == "${ZOOM_INSTALLED_VERSION}" ]]; then
		logger_cmd "Info: Zoom is up-to-update"
        ZOOM_UPTODATE=yes
		return 0
    else
	    logger_cmd "Info: Zoom is not up-to-update"
        ZOOM_UPTODATE=no
        return 1
    fi
}

function is_zoom_running() {
    # this function will determine if zoom is running or not.
    logger_cmd "Info: Checking if zoom.us is running"
    if pgrep zoom.us >/dev/null ; then
        logger_cmd "Info: zoom.us is running"
        ZOOM_IS_RUNNING=yes
        return 0
    else
        logger_cmd "Info: zoom.us is not running"
        ZOOM_IS_RUNNING=no
        return 1
    fi
}

function is_zoom_meeting_inprogress() {
    # this function will determine if a zoon meeting is in progress or not.
    logger_cmd "Info: Checking if a zoom meeting is in progress"
    if pgrep CptHost >/dev/null ; then
        logger_cmd "Warn: There is a zoom meeting in progress"
        ZOOM_MEETING_INPROGRESS=yes
        return 0
    else
        logger_cmd "Info: There are no zoom meetings in progress"
        ZOOM_MEETING_INPROGRESS=no
        return 1
    fi    
}

function is_zoom_url_valid() {
    # this function will test the zoom download url to see if it valid or not.
    logger_cmd "Info: Validating zoom download url"
    if curl -o /dev/null -sI --fail "${ZOOM_DOWNLOAD_URL}" --retry 3; then
        logger_cmd "Info: The url ${ZOOM_DOWNLOAD_URL} is valid"
        return 0
    else
        logger_cmd "Error: The url ${ZOOM_DOWNLOAD_URL} is invalid"
        return 1
    fi
}

function download_zoom_pkg() {
    # this function will use the download url to download the pkg from the cdn
    logger_cmd "Info: Downloading ${ZOOM_PKG_NAME} from ${ZOOM_DOWNLOAD_URL}"
    if curl -Lso "${ZOOM_PKG_PATH}" "${ZOOM_DOWNLOAD_URL}" --retry 3; then
        logger_cmd "Info: ${ZOOM_PKG_NAME} was download to ${ZOOM_TMP_DIRECTORY}"
        return 0
    else
        logger_cmd "Error: ${ZOOM_PKG_NAME} download failed, please try again later"
        return 1
    fi
}

function install_zoom_pkg() {
    # this function will install the zoom app using macOS installer command
    logger_cmd "Info: Installing zoom, check /var/log/install.log for progress"
    until installer -pkg "${ZOOM_PKG_PATH}" -target / ; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ -d "${ZOOM_APP_PATH}" ]]; then
        logger_cmd "Info: Zoom is now installed"
        return 0
    else
        logger_cmd "Error: Zoom was not installed"
        return 1
    fi
}

function install_zoom_audio_device() {
    # this function installs the zoom audio device for sharing audio.
    if [[ -d "/Library/Audio/Plug-Ins/HAL/ZoomAudioDevice.driver" ]]; then
        logger_cmd "Info: Zoom Audio Device is already installed"
        return 0
    else
        logger_cmd "Warm: Zoom Audio Device not installed"
        logger_cmd "Info: Installing Zoom Audio Device"
        until cp -R "/Applications/zoom.us.app/Contents/PlugIns/ZoomAudioDevice.driver" "/Library/Audio/Plug-Ins/HAL/"; do
            ((c++)) && ((c==5)) && break
            sleep 1
        done
        if [[ -d "/Library/Audio/Plug-Ins/HAL/ZoomAudioDevice.driver" ]]; then
            logger_cmd "Info: Zoom Audio Device was installed successfully"
            logger_cmd "Info: Restarting Core Audio Daemon"
            until killall coreaudiod; do
                ((c++)) && ((c==5)) && break
                sleep 1
            done
            return 0
        else
            logger_cmd "Error: Zoom Audio Device was not installed"
            return 1
        fi
    fi
}

function clean_up() {
    # this function cleans up temporary files.
    logger_cmd "Info: Removing temporary files"
    until rm -rf "${ZOOM_TMP_DIRECTORY}"; do
        ((c++)) && ((c==5)) && break
        sleep 1
    done
    if [[ ! -d "${ZOOM_TMP_DIRECTORY}" ]]; then
        logger_cmd "Info: Zoom temporary files were removed correctly"
        return 0
    else
        logger_cmd "Error: Zoom temporary files were not removed correctly"
        return 1
    fi
}

function main() {
    # this is the main function to run and control all other functions
    logger_cmd "Info: Starting function is_zoom_url_valid"
    if is_zoom_url_valid; then
        logger_cmd "Info: function is_zoom_url_valid finished successfully"
    else
        logger_cmd "Error: function is_zoom_url_valid failed"
        clean_up
        exit 1
    fi

    logger_cmd "Info: Starting function download_zoom_pkg"
    if download_zoom_pkg; then
        logger_cmd "Info: function download_zoom_pkg finished successfully"
    else
        logger_cmd "Error: function download_zoom_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "Info: Starting function install_zoom_pkg"
    if install_zoom_pkg; then
        logger_cmd "Info: function install_zoom_pkg finished successfully"
        if [[ "${ZOOM_IS_RUNNING}" == "yes" ]]; then
            logger_cmd "Info: Re-launching zoom again"
            open -F "${ZOOM_APP_PATH}" &
        fi
    else
        logger_cmd "Error: function install_zoom_pkg failed"
        clean_up
        exit 1
    fi

    logger_cmd "Info: Starting function install_zoom_audio_device"
    if install_zoom_audio_device; then
        logger_cmd "Info: function install_zoom_audio_device finished successfully"
    else
        logger_cmd "Error: function install_zoom_audio_device failed"
    fi
   
    logger_cmd "Info: Starting function clean_up"
    if clean_up; then
        logger_cmd "Info: function clean_up finished successfully"
    else
        logger_cmd "Error: function clean_up failed"
        exit 1
    fi
}

# this section or the script performs all the tests.

if [[ ! -d "${ZOOM_APP_PATH}" ]]; then
    # Zoom is not installed, download and install latest version.
    logger_cmd "Info: Zoom is not installed, perform fresh install"
    logger_cmd "Info: Installing zoom in the background"
    main
else
    # Zoom is installed, run tests to determine install procedure.
    is_zoom_up_to_date
    is_zoom_running
    is_zoom_meeting_inprogress
    if [[ -d "${ZOOM_APP_PATH}" ]] && [[ "${ZOOM_UPTODATE}" == "yes" ]]; then
        logger_cmd "Info: Zoom is installed, and up-to-date."
        logger_cmd "Info: All looks good. Nothing to do. Exiting."
        clean_up
        exit 0
    elif [[ -d "${ZOOM_APP_PATH}" ]] && [[ "${ZOOM_UPTODATE}" == "no" ]] && [[ "${ZOOM_IS_RUNNING}" == "yes" ]] && [[ "${ZOOM_MEETING_INPROGRESS}" == "yes" ]]; then
        logger_cmd "Info: Zoom is installed, is not up-to-date, running, meeting in progress."
        logger_cmd "Warn: Meeting in progress. Nothing to do. Exiting."
        clean_up
        exit 0
    elif [[ -d "${ZOOM_APP_PATH}" ]] && [[ "${ZOOM_UPTODATE}" == "no" ]] && [[ "${ZOOM_IS_RUNNING}" == "no" ]]; then
        logger_cmd "Info: Zoom is installed, is not up-to-date and not running"
        logger_cmd "Info: Update zoom in the background"
        main
    elif [[ -d "${ZOOM_APP_PATH}" ]] && [[ "${ZOOM_UPTODATE}" == "no" ]] && [[ "${ZOOM_IS_RUNNING}" == "yes" ]] && [[ "${ZOOM_MEETING_INPROGRESS}" == "no" ]]; then
        logger_cmd "Info: Zoom is installed, not up-to-date, running, no meetings in progress."
        if jamfhelper_zoom_update; then
            USER_PRESSED_UPDATE="yes"
        else
            USER_PRESSED_UPDATE="no"
        fi
        if [[ "${USER_IDLE_TIME}" -eq "0" ]] && [[ "${USER_PRESSED_UPDATE}" == "yes" ]]; then
            logger_cmd "Info: User is not idle, and update was pressed. Quit Zoom and update in background."
            until pkill "zoom.us" >/dev/null 2>&1; do
                logger_cmd "Info: Quitting zoom..."
                ((c++)) && ((c==5)) && break
                sleep 1
            done
            main
        elif [[ "${USER_IDLE_TIME}" -eq "0" ]] && [[ "${USER_PRESSED_UPDATE}" == "no" ]]; then
            logger_cmd "Warn: User is not idle, and defer was pressed. Exiting."
            exit 1
        fi
        if [[ "${USER_IDLE_TIME}" -gt "60" ]]; then
            logger_cmd "Info: User is idle. Quit Zoom and update in background."
            until pkill "zoom.us" >/dev/null 2>&1; do
                logger_cmd "Info: Quitting Zoom."
                ((c++)) && ((c==5)) && break
                sleep 1
            done
            main
        fi
    fi
fi
