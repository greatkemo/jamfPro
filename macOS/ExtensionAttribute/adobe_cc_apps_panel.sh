#!/bin/bash

# Define the XML file path
XML_FILE="/Library/Application Support/Adobe/OOBE/Configs/ServiceConfig.xml"

# XPath query to extract the 'visible' value for 'AppsPanel'
XPATH_QUERY="//panel[name='AppsPanel']/visible/text()"

# Extract the value using xmllint
AppsPanelVisible=$(xmllint --xpath "$XPATH_QUERY" "$XML_FILE" 2>/dev/null)

# Check if AppsPanel is enabled (visible) and output the result
if [ "$AppsPanelVisible" = "true" ]; then
    echo "<result>Enabled</result>"
else
    echo "<result>Disabled</result>"
fi
