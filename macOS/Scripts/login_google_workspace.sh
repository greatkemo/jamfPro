#!/bin/bash

# This script opens the Google Workspace login page in Google Chrome, then waits for the user to successfully login.

# Function to get the current console user
CONSOLE_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Check if the domain is passed as an argument
if [ -z "$4" ]; then
    echo "Error: No domain specified. Please provide the domain as an argument."
    exit 1
fi

# Set the DOMAIN variable with the value from $4
DOMAIN="$4"

# Assemble the USER_ID
USER_ID="${CONSOLE_USER}@${DOMAIN}"

# Define the URL, incorporating the DOMAIN variable
ACCOUTNS_URL="https://accounts.google.com/samlredirect?domain=$DOMAIN"

# Open the URL in Google Chrome
sudo -u "$CONSOLE_USER" open -a "Google Chrome" "$ACCOUTNS_URL"

# Path to the Local State file in Google Chrome's user data directory
LOCAL_STATE_FILE="/Users/$CONSOLE_USER/Library/Application Support/Google/Chrome/Local State"

# Initialize counter
c=0

# Loop until USER_ID is found in Local State or 60 seconds have passed
until grep -q "$USER_ID" "$LOCAL_STATE_FILE"; do
    # Increment the counter and check if 60 seconds have elapsed
    ((c++)) && ((c==180)) && break
    echo "Waiting for successful login to Google Workspace for $USER_ID..."
        # echo how many seconds are remaining
        echo "$((60-c)) seconds remaining..."
    sleep 1
done

# Check the outcome of the loop
if ((c==60)); then
    # If loop times out, exit with code 99
    echo "Time out: USER_ID not found in Local State within 60 seconds."
    exit 99
elif grep -q "$USER_ID" "$LOCAL_STATE_FILE"; then
    # If USER_ID is found, open mail.google.com in Google Chrome
    echo "USER_ID found in Local State. Opening Gmail in Google Chrome."
    open -a "Google Chrome" "https://mail.google.com/"
    exit 0
else
    # If USER_ID is not correct, exit with code 98
    echo "Incorrect USER_ID."
    exit 98
fi
