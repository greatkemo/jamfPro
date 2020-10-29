#!/bin/bash

if [[ -d "/Applications/Google Drive File Stream.app" ]]; then
  gdfs_version=$(defaults read "/Applications/Google Drive File Stream.app/Contents/info.plist" CFBundleVersion)
  echo "<result>${gdfs_version}</result>"
else
  echo "<result>Not Installed</result>"
fi

exit 0
