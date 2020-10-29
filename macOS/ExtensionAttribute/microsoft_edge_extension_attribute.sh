#!/bin/bash

if [[ -d "/Applications/Microsoft Edge.app" ]]; then
  edge_version=$(defaults read "/Applications/Microsoft Edge.app/Contents/info.plist" CFBundleVersion)
  echo "<result>${edge_version}</result>"
else
  echo "<result>Not Installed</result>"
fi

exit 0
