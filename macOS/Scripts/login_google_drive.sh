#!/bin/bash

# This script opens the Google Drive login Window and whits for the user to successfully login.

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

# Open Google Drive as the console user
sudo -u "$CONSOLE_USER" open -a "Google Drive"

# Define the path to the Google Drive folder for the user
GOOGLE_DRIVE_USER_PATH="/Users/$CONSOLE_USER/Library/CloudStorage/GoogleDrive-$USER_ID"

# Initialize counter
c=0

# Loop until Google Drive folder for the user is created or 60 seconds have passed
until [ -d "$GOOGLE_DRIVE_USER_PATH" ]; do
    # Increment the counter and check if 60 seconds have elapsed
    ((c++)) && ((c==180)) && break
    echo "Waiting for $USER_ID to log in to Google Drive..."
    echo "$((60-c)) seconds remaining..."
    sleep 1
done

# Check the outcome of the loop
if ((c==60)); then
    # If loop times out, exit with code 99
    echo "Time out: $USER_ID has not logged into Google Drive within 60 seconds."
    exit 99
elif [ -d "$GOOGLE_DRIVE_USER_PATH" ]; then
    # If the Google Drive folder for the user is found, exit with code 0
    echo "Login successful for $USER_ID in Google Drive."
    exit 0
else
    # If the user path is not correct, exit with code 98
    echo "Incorrect USER_ID or login issue."
    exit 98
fi
