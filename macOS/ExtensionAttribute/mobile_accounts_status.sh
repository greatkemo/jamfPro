#!/bin/bash

# Check if mobile accounts are enabled or not
mobile_accounts=$(dsconfigad -show | grep "Create mobile account at login" | awk '{print $NF}')
if [ "$mobile_accounts" == "Enabled" ]; then
  echo "<result>Mobile Accounts Enabled</result>"
else
  echo "<result>Mobile Accounts Disabled</result>"
fi

exit 0
