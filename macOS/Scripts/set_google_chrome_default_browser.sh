#!/bin/bash

# This script sets Google Chrome as the default browser for the current console user, 
# then macOS will prompt the user to confirm the change.

# Function to get the current console user
CONSOLE_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Function to check if Google Chrome is the default browser for a given user
check_default_browser() {
    HTTPS_HANDLER=$( sudo -u "$CONSOLE_USER" defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
    | grep -B 1 -A 1 "https" \
    | grep "LSHandlerRoleAll" \
    | awk '{print $3}' \
    | sed 's/;//' \
    | sed 's/"//g' )
    
    if [[ "$HTTPS_HANDLER" == "com.google.chrome" ]]; then
        return 0  # Chrome is the default
    else
        return 1  # Chrome is not the default
    fi
}

# Check if Chrome is not the default browser and set it as default
if ! check_default_browser; then
    echo "Google Chrome is not the default browser for $CONSOLE_USER."
    echo "Setting Google Chrome as the default browser for $CONSOLE_USER..."
    sudo -u "$CONSOLE_USER" open -a "Google Chrome" --new --args --make-default-browser

    # Initialize counter
    c=0

    # Loop until Chrome is the default or 60 seconds have passed
    until check_default_browser; do
        ((c++)) && ((c==60)) && break
        echo "Waiting for Google Chrome to be set as the default browser for $CONSOLE_USER..."
        # echo how many seconds are remaining
        echo "$((60-c)) seconds remaining..."
        sleep 1
    done

    if ((c==60)); then
        # If loop times out, exit with code 98
        echo "Failed to set Google Chrome as the default browser for $CONSOLE_USER within 60 seconds."
        exit 98
    else
        echo "Google Chrome is now the default browser for $CONSOLE_USER."

        # Quit Google Chrome
        sudo -u "$CONSOLE_USER" osascript -e 'tell application "Google Chrome" to quit'

        exit 0
    fi
else
    echo "Google Chrome is already the default browser for $CONSOLE_USER."
fi

# If the validation fails for another reason, exit with code 99
exit 99
