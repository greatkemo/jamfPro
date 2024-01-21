#!/bin/bash

# This script opens the Zoom application and waits for the user to successfully login with SSO.

# Function to get the current console user
CONSOLE_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

PLIST="/Users/$CONSOLE_USER/Library/Preferences/us.zoom.xos.plist"

# Open the Zoom application as the console user
sudo -u "$CONSOLE_USER" open -a "zoom.us"

# Initialize counter
c=0

# Loop until LastLoginType is 'sso' or 60 seconds have passed
while [ "$(sudo -u "$CONSOLE_USER" defaults read "$PLIST" LastLoginType)" != "sso" ]; do
    # Increment the counter and check if 60 seconds have elapsed
    ((c++)) && ((c==180)) && break
    echo "Waiting for SSO login on Zoom..."
    echo "$((60-c)) seconds remaining..."
    sleep 1
done

# Check the outcome of the loop
if ((c==60)); then
    # If loop times out, exit with code 1
    echo "Time out: SSO login not detected within 60 seconds."
    exit 1
elif [ "$(sudo -u "$CONSOLE_USER" defaults read "$PLIST" LastLoginType)" == "sso" ]; then
    # If SSO login is detected, exit with code 0
    echo "SSO login detected on Zoom."
    exit 0
else
    # If the condition is not met, exit with code 2
    echo "An unknown error occurred."
    exit 2
fi
