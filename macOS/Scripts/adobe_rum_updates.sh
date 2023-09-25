#!/bin/bash

# Global Variables
RUM_PATH="/usr/local/bin/RemoteUpdateManager"
RELEASE_NOTES_URL="https://helpx.adobe.com/enterprise/kb/rum-release-notes.html"
LOG_FILE="/Library/Logs/adobe_rum.log"

# Logging function
log() {
    # Check if the log file exists
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
    # Log the message with timestamp to the log file
    echo "$( date "+%Y-%m-%d %H:%M:%S" ) - $1" >> "$LOG_FILE"
    # Log the message to stdout as well
    echo "$1"
}

# Check if Adobe products are installed
if ! ls /Applications/Adobe* 1>/dev/null 2>&1; then
    log "Error: No Adobe products detected. Exiting..."
    exit 1
fi

# Function to download and mount RUM dmg
download_rum() {
    # Decide the RUM URL based on the chipset
    if [[ "$( uname -m )" == "arm64" ]]; then
        RUM_DMG_URL="https://deploymenttools.acp.adobeoobe.com/RUM/AppleSilicon/RemoteUpdateManager.dmg"
    else
        RUM_DMG_URL="https://deploymenttools.acp.adobeoobe.com/RUM/MacIntel/RemoteUpdateManager.dmg"
    fi

    # Download RUM
    log "Downloading RUM from $RUM_DMG_URL..."
    if ! curl -o "/tmp/RemoteUpdateManager.dmg" --retry 3 "$RUM_DMG_URL" --silent; then
        log "Error: Failed to download RUM"
        exit 1
    fi

    # Mount the dmg
    hdiutil attach "/tmp/RemoteUpdateManager.dmg" -nobrowse -quiet
}

# Cleanup function
cleanup() {
    hdiutil detach "/Volumes/RUM" -quiet
    rm "/tmp/RemoteUpdateManager.dmg"
}

# Check if RUM is running and quit it
quit_rum_if_running() {
    RUM_PID=$( pgrep RemoteUpdateManager )
    if [[ $RUM_PID ]]; then
        log "RUM is currently running with PID $RUM_PID. Quitting..."
        kill -9 "$RUM_PID"
    fi
}

# Get the latest version of RUM
LATEST_VERSION=$(curl -s "$RELEASE_NOTES_URL" | grep -oE 'Version [0-9]+\.[0-9]+' | head -1 | cut -d' ' -f2)

if [[ -f "$RUM_PATH" ]]; then
    # Get the current installed version of RUM
    CURRENT_VERSION=$($RUM_PATH -h 2>/dev/null | awk -F': ' '{print $2}' | cut -d'.' -f1,2)
    log "Installed RUM version: $CURRENT_VERSION"
    log "Latest RUM version: $LATEST_VERSION"

    # Compare the current version with the latest
    if [[ "$CURRENT_VERSION" < "$LATEST_VERSION" ]]; then
        log "An update is available for RUM. Downloading..."
        quit_rum_if_running
        download_rum
        UPDATE_REQUIRED=1
    else
        log "RUM is already up-to-date."
    fi
else
    log "RUM is not installed. Downloading..."
    download_rum
    UPDATE_REQUIRED=1
fi

if [[ "$UPDATE_REQUIRED" == "1" ]]; then
    # Copy the binary to the desired location
    cp "/Volumes/RUM/RemoteUpdateManager" "$RUM_PATH"

    # Set the permissions and owner
    chmod 755 "$RUM_PATH"
    chown root:wheel "$RUM_PATH"

    # Cleanup
    cleanup
fi

# Run the RUM tool to update Adobe apps
log "Updating Adobe applications..."
$RUM_PATH

log "Process completed."
