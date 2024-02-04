#!/bin/bash

# XML file path
XML_FILE="/Library/Application Support/Adobe/OOBE/Configs/ServiceConfig.xml"

# Variable that holds the desired state ('true' or 'false'), passed as the fourth argument
DESIRED_STATE="$4" # This will be 'true' or 'false' based on the argument passed in Jamf Pro

# XPath query to find the 'visible' element for 'AppsPanel'
XPATH_QUERY="//panel[name='AppsPanel']/visible"

# Current state of 'visible' for 'AppsPanel'
CURRENT_STATE=$(xmllint --xpath "string($XPATH_QUERY/text())" "$XML_FILE" 2>/dev/null)

# Check if the current state is different from the desired state
if [ "$CURRENT_STATE" != "$DESIRED_STATE" ]; then
    # Use sed to replace the value
    # This creates a backup file with '.bak' extension
    sed -i.bak "s|<visible>$CURRENT_STATE</visible>|<visible>$DESIRED_STATE</visible>|g" "$XML_FILE"
    echo "AppsPanel visibility changed to $DESIRED_STATE."
else
    echo "AppsPanel visibility is already set to $DESIRED_STATE."
fi
