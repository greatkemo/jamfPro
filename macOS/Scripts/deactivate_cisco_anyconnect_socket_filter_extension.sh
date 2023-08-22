#!/bin/bash

# Configuration
DEACTIVATE_CMD="/Applications/Cisco/Cisco AnyConnect Socket Filter.app/Contents/MacOS/Cisco AnyConnect Socket Filter"
APP_PATH="/Applications/Cisco/Cisco AnyConnect Socket Filter.app"
LOGFILE="/var/log/cisco_socket_filter_uninstall.log"
RETRIES=5

# Exit codes:
# 0 - Successful completion
# 1 - General error (like if the command is missing or no active extensions found)
# 2 - Failed to deactivate extension after 3 tries
# 3 - Failed to remove the app

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOGFILE"
}

deactivate_extensions() {
    for ((i=1; i<=RETRIES; i++)); do
        "${DEACTIVATE_CMD}" -deactivateExt

        # Check the status
        local CURRENT_COUNT
        CURRENT_COUNT=$(systemextensionsctl list | grep -c 'com.cisco.anyconnect.macos.acsockext.*activated enabled')
        
        if [ "${CURRENT_COUNT}" -eq 0 ]; then
            log "Successfully deactivated all extensions on attempt $i."
            return 0
        else
            log "Attempt $i to deactivate the extensions resulted in ${CURRENT_COUNT} still active."
            sleep 2
        fi
    done

    log "Failed to deactivate all extensions after ${RETRIES} tries."
    exit 2
}

remove_app() {
    if [ -d "${APP_PATH}" ]; then
        log "Removing app..."
        if rm -rf "${APP_PATH}"; then
            log "Successfully removed app."
            return 0
        else
            log "Failed to remove app."
            exit 3
        fi
    else
        log "App not found."
        return 0
    fi
}

# Main
log "Initiating deactivation and removal process..."

ACTIVE_COUNT=$(systemextensionsctl list | grep -c 'com.cisco.anyconnect.macos.acsockext.*activated enabled')
if [[ -f "${DEACTIVATE_CMD}" && ${ACTIVE_COUNT} -gt 0 ]]; then
    if deactivate_extensions; then
        remove_app
        log "Successfully completed deactivation and removal."
        exit 0
    else
        exit 2  # This exit code might be redundant since `deactivate_extensions` already has an exit statement, but it provides clarity.
    fi
else
    log "No active extensions found or deactivation command missing."
    exit 1
fi
