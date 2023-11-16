#!/bin/bash

# Script Description:
# This script is designed to manage the uninstallation of Adobe Acrobat Reader on macOS systems,
# specifically when Adobe Acrobat Pro is also installed. The script ensures that users do not have
# both Adobe Acrobat Reader and Adobe Acrobat Pro installed simultaneously, prioritizing Acrobat Pro.

# Dependencies:
# 1. SwiftDialog (/usr/local/bin/dialog): Used for displaying user-friendly dialog boxes.
#    The script checks for its presence and uses it for user interaction if available.
# 2. Adobe Acrobat Reader and Adobe Acrobat Pro: Paths and package identifiers used in the script are based on standard installations of these applications.
# 3. macOS Command Line Tools: This script uses tools like ioreg, pgrep, and kill, which are standard on macOS systems.

# Key Features:
# 1. Checks if Adobe Acrobat Pro is installed. If not, Acrobat Reader will not be uninstalled.
# 2. Determines if the user is idle for less than 5 minutes. If so, and if SwiftDialog is available,
#    displays a dialog informing the user about the uninstallation of Acrobat Reader.
# 3. If the user is idle for more than 5 minutes, or if SwiftDialog is not installed,
#    proceeds to kill any running Acrobat Reader processes and uninstall the application.
# 4. Uses package identifiers to remove all components associated with Acrobat Reader.
# 5. Includes logging for monitoring and debugging purposes.

# Usage:
# Save this script as 'uninstall_acrobat_reader.sh' and execute it with administrative privileges.
# Example: sudo ./uninstall_acrobat_reader.sh

# Note:
# This script should be used with caution and tested in a controlled environment before deployment.
# It is important to have backups and ensure that critical data is not lost during the uninstallation process.

# Function to log messages
log_message() {
    echo "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/adobe_reader_uninstall.log
}

# Function to check for SwiftDialog
check_swiftdialog() {
    if [ -f "/usr/local/bin/dialog" ]; then
        log_message "SwiftDialog is installed."
        return 0
    else
        log_message "SwiftDialog is not installed."
        return 1
    fi
}

# Function to get user idle time in seconds
get_user_idle_time() {
    ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}'
}

# Function to display prompt using SwiftDialog
display_prompt() {
    log_message "Displaying prompt to user."
    local dialog_cmd="/usr/local/bin/dialog"
    local iconPath="/Applications/Adobe Acrobat Reader.app"
    local iconOverlayPath="/System/Library/CoreServices/Installer.app"
    local buttonText="Quit and Uninstall"
    local title="Update to Adobe Acrobat Pro"
    local message="We've noticed that **both Adobe Acrobat Reader and Adobe Acrobat Pro are installed** on your system.<br><br>To streamline your experience and fully utilize the features of Acrobat Pro:<br> * Adobe Acrobat Reader will be **uninstalled**.<br> * **Please Save Your Work**: Ensure all your documents are saved.<br> * **Next Steps**: Click **'Quit and Uninstall'** to proceed.<br> * **Auto-close Notice**: This dialog will automatically close in 5 minutes if no action is taken.<br><br>_Thank you for your cooperation in enhancing your system's performance._"
    $dialog_cmd command -m "$message" \
                        --icon "$iconPath" \
                        --iconsize 200 \
                        --overlayicon "$iconOverlayPath" \
                        --button1text "$buttonText" \
                        --timeout 300 --quit "none" \
                        --title "$title" \
                        --ontop \
                        --moveable \
                        --position center \
                        --big \
                        --buttonstyle center
}

# New Function to terminate all Acrobat Reader processes
terminate_acrobat_reader_processes() {
    # Find all processes related to Acrobat Reader
    log_message "Finding Acrobat Reader processes..."
    local pids
    pids=$(pgrep -f "Acrobat Reader")
    # Check if any processes were found
    if [ -n "$pids" ]; then
        log_message "Found processes: $pids"
        log_message "Acrobat Reader processes found. Attempting to terminate..."

        # Attempt to kill all found processes
        for pid in $pids; do
            kill "$pid" 2>/dev/null
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                log_message "Failed to terminate process $pid. Attempting 'kill -9'."
                kill -9 "$pid" 2>/dev/null
            fi
        done

        # Final check to ensure all processes are terminated
        if pgrep -f "Acrobat Reader" > /dev/null; then
            log_message "Unable to terminate all Acrobat Reader processes. Please close them manually before proceeding."
            exit 1
        fi
    else
        log_message "No Acrobat Reader processes running."
    fi
}

# Function to uninstall Acrobat Reader
uninstall_acrobat_reader() {
    # First, terminate all Acrobat Reader processes
    log_message "Running terminte_acrobat_reader_processes() function..."
    terminate_acrobat_reader_processes

    # Remove the application and associated components
    local packages=(
        "com.adobe.RdrServicesUpdater" 
        "com.adobe.acrobat.DC.reader.acropython3.pkg.MUI" 
        "com.adobe.acrobat.DC.reader.app.pkg.MUI" 
        "com.adobe.acrobat.DC.reader.appsupport.pkg.MUI" 
        "com.adobe.armdc.app.pkg"
        )
    for pkg in "${packages[@]}"; do
        local files
        files=$(pkgutil --files "$pkg")
        if [ -n "$files" ]; then
            log_message "Uninstalling package $pkg"
            for file in $files; do
                rm -rf "${file:?}"
            done
            pkgutil --forget "$pkg"
        else
            log_message "Package $pkg not found or already uninstalled."
        fi
    done
    rm -rf "/Applications/Adobe Acrobat Reader.app"
    log_message "Adobe Acrobat Reader and associated components have been removed."
}

# Main script logic
if [ -d "/Applications/Adobe Acrobat DC/Adobe Acrobat.app" ]; then
    log_message "Adobe Acrobat Pro is installed."
    if [ -d "/Applications/Adobe Acrobat Reader.app" ]; then
        log_message "Adobe Acrobat Reader is installed."
        if check_swiftdialog && pgrep -x "Acrobat Reader" > /dev/null && [ "$(get_user_idle_time)" -lt 300 ]; then
            log_message "Running display_prompt() function..."
            display_prompt
            log_message "Running uninstall_acrobat_reader() function..."
            uninstall_acrobat_reader
            log_message "Adobe Acrobat Reader has been uninstalled after user confirmation or timeout."
        else
            log_message "Running uninstall_acrobat_reader() function..."
            uninstall_acrobat_reader
            log_message "Adobe Acrobat Reader has been uninstalled automatically due to user inactivity."
        fi
    else
        log_message "Adobe Acrobat Reader is not installed. No action needed."
    fi
else
    log_message "Adobe Acrobat Pro is not installed. Adobe Acrobat Reader will not be uninstalled."
fi
