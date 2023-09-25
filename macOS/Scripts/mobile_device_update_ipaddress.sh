#!/bin/bash

# Get Jamf Pro server URL and remove trailing /
JAMF_URL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's/\/$//')
echo "Jamf Pro URL: $JAMF_URL"

# Prompt for Username and Password
echo "Please enter your Jamf Pro credentials."
read -rp "Username: " USERNAME
read -srp "Password: " PASSWORD
echo

# Create base64-encoded credentials
echo "Encoding credentials..."
ENCODED_CREDENTIALS=$(printf "$USERNAME:$PASSWORD" | iconv -t ISO-8859-1 | base64 -i - )
echo "Encoded credentials: $ENCODED_CREDENTIALS"

# Generate Auth Token for Classic API
echo "Generating authentication token..."
AUTH_TOKEN=$( curl "$JAMF_URL/uapi/auth/tokens" \
     --silent \
     --request POST \
     --header "Authorization: Basic $ENCODED_CREDENTIALS" )

# Parse AUTH_TOKEN for TOKEN to omit expiration
TOKEN=$( awk -F \" '{ print $4 }' <<< "$AUTH_TOKEN" | xargs )
echo "Token: $TOKEN"

# Prompt for Device ID
echo "Please enter the ID of the mobile device you wish to update."
read -rp "Device ID: " DEVICE_ID
echo "Device ID: $DEVICE_ID"

# Endpoint URL for mobile device
echo "Generating device URL..."
DEVICE_URL="$JAMF_URL/JSSResource/mobiledevices/id/$DEVICE_ID"
echo "Entered Device URL: $DEVICE_URL"

# Get current IP address
echo "Getting current IP address..."
CURRENT_IP=$(curl "$DEVICE_URL" \
     --silent \
     --request GET \
     --header "Authorization: Bearer $TOKEN"  \
     | xmllint --format --xpath "//general/ip_address/text()" -)
echo "Current IP Address: $CURRENT_IP"

# Prompt for New IP Address
echo "Please enter the new IP address for the mobile device."
read -rp "New IP Address: " IP_ADDRESS

# XML Data
echo "Generating XML data..."
DATA="<mobile_device><general><ip_address>$IP_ADDRESS</ip_address></general></mobile_device>"
echo "XML Data: $DATA"

# Send PUT request
echo "Updating IP address..."
curl "$DEVICE_URL" \
    --silent \
    --request PUT \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: text/xml" \
    --data "$DATA" >/dev/null

# Get response
RESPONSE=$(curl "$DEVICE_URL" \
     --silent \
     --request GET \
     --header "Authorization: Bearer $TOKEN"  \
     | xmllint --format --xpath "//general/ip_address/text()" -)
echo "Response: $RESPONSE"

# Check if the update was successful
if [[ "$RESPONSE" == "$IP_ADDRESS" ]]; then
    echo "IP address updated successfully."
elif [[ "$RESPONSE" == "$CURRENT_IP" ]]; then
    echo "Failed to update IP address."
else
    echo "Unknown error."
fi

# Invalidate Token
echo "Invalidating token..."
curl "$JAMF_URL/uapi/auth/invalidateToken" \
    --silent \
    --request POST \
    --header "Authorization: Bearer $TOKEN"

echo "Done."