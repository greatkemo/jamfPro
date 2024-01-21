#!/bin/bash

# Jamf Pro Extension Attribute to check if the user has completed macos onboarding
# Get the current console user using scutil
CONSOLE_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Check if a user is logged in
if [ -n "$CONSOLE_USER" ]; then
    echo "Current console user: $CONSOLE_USER"
    PLIST="/Users/$CONSOLE_USER/Library/Preferences/com.jamfsoftware.selfservice.mac.plist"
    if  [[ $(defaults read "$PLIST" com.jamfsoftware.selfservice.onboardingcomplete) == "1" ]]; then
        echo "<result>Complete</result>"
    else
        echo "<result>Incomplete</result>"
    fi
else
    echo "No user currently logged in at the console."
    exit 0
fi



