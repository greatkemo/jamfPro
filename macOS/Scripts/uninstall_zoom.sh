#!/bin/bash

#
# uninstall_zoom.sh
#
# This script uninstalls Zoom from a macOS system.
# It kills all Zoom processes running on the system (if any), removes the Zoom app from the Applications folder (if present),
# removes Zoom directories for all users (if present), and forgets the package receipt for Zoom (if present).
# It also logs the result of each step to a log file (/var/log/zoom_uninstall.log).
#
# This script is intended to be used with a management system such as Jamf Pro.
# It should be run as root.
#

# Configuration
APP_PATH="/Applications/zoom.us.app"
LOGFILE="/var/log/zoom_uninstall.log"
USER_DIRS="/Users/*"
ZOOM_DIRS=(
    "Library/Application Support/zoom.us"
    "Library/Caches/us.zoom.xos"
    "Library/Logs/zoom.us"
    "Library/Preferences/us.zoom.xos.plist"
    "Library/Saved Application State/us.zoom.xos.savedState"
)
PACKAGE_RECEIPT="us.zoom.pkg.videomeeting"

# Exit codes:
# 0 - Successful completion
# 1 - General error
# 2 - Failed to kill Zoom processes
# 3 - Failed to remove Zoom app
# 4 - Failed to remove a Zoom directory
# 5 - Failed to forget package receipt

# Functions
# Log to file and stdout with timestamp prepended to each line of output
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE"
}

# Kill all Zoom processes running on the system (if any) and log the result to the log file
kill_zoom_processes() {
    local ZOOM_PIDS
    ZOOM_PIDS=$(pgrep "zoom.us")
    if [ -n "$ZOOM_PIDS" ]; then
        log "Killing Zoom processes..."
        if ! kill -9 "$ZOOM_PIDS" 2>/dev/null; then
            log "Failed to kill all Zoom processes."
            exit 2
        else
            log "All Zoom processes killed successfully."
        fi
    else
        log "No Zoom processes found running."
    fi
}

# Remove Zoom app from the Applications folder (if present) and log the result to the log file
remove_zoom_app() {
    if [ -d "$APP_PATH" ]; then
        log "Removing Zoom app..."
        if ! rm -rf "$APP_PATH"; then
            log "Failed to remove Zoom app."
            exit 3
        else
            log "Zoom app removed successfully."
        fi
    else
        log "Zoom app not found."
    fi
}

# Remove Zoom directories for a given user (if present) and log the result to the log file
remove_zoom_dirs_for_user() {
    local USER_PATH=$1
    for dir in "${ZOOM_DIRS[@]}"; do
        local TARGET="$USER_PATH/$dir"
        if [ -e "$TARGET" ]; then
            log "Removing directory/file: $TARGET"
            if ! rm -rf "$TARGET"; then
                log "Failed to remove $TARGET."
                exit 4
            else
                log "Successfully removed $TARGET."
            fi
        else
            log "Directory/file $TARGET not found."
        fi
    done
}

# Forget package receipt for Zoom (if present) and log the result to the log file
forget_package_receipt() {
    if pkgutil --pkg-info "$PACKAGE_RECEIPT" > /dev/null 2>&1; then
        log "Forgetting package receipt: $PACKAGE_RECEIPT"
        pkgutil --forget "$PACKAGE_RECEIPT"
        if ! pkgutil --forget "$PACKAGE_RECEIPT"; then
            log "Failed to forget package receipt: $PACKAGE_RECEIPT."
            exit 5
        else
            log "Successfully forgot package receipt: $PACKAGE_RECEIPT."
        fi
    else
        log "Package receipt $PACKAGE_RECEIPT not found."
    fi
}

# Main
# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi
# Check if the log file exists and create it if it doesn't
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
fi
# Start the uninstallation process
log "Initiating Zoom uninstallation process..."
# Kill Zoom processes, remove Zoom app, remove Zoom directories for all users, and forget package receipt
kill_zoom_processes
remove_zoom_app
for user_dir in $USER_DIRS; do
    if [ -d "$user_dir" ]; then
        remove_zoom_dirs_for_user "$user_dir"
    fi
done
forget_package_receipt
# Finish the uninstallation process
log "Zoom uninstallation completed successfully."
exit 0