#!/bin/bash

if [[ -d /Applications/zoom.us.app ]]; then
  zoom_version=$(defaults read "/Applications/zoom.us.app/Contents/info.plist" CFBundleVersion)
  echo "<result>${zoom_version}</result>"
else
  echo "<result>Not Installed</result>"
fi

exit 0
