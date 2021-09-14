#!/bin/bash

MACOS_VERSION=$(sw_vers -productVersion | sed 's/[.]/_/g')
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X ${MACOS_VERSION}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"
zoom_app_path="/Applications/zoom.us.app"
ZOOM_LATEST_VERSION=$(curl -s -A "${USER_AGENT}" https://zoom.us/download | grep 'ZoomInstallerIT.pkg' | awk -F'/' '{print $3}')
ZOOM_INSTALLED_VERSION=$(defaults read ${zoom_app_path}/Contents/Info CFBundleVersion | sed -e 's/0 //g' -e 's/(//g' -e 's/)//g')

if [[ "${ZOOM_LATEST_VERSION}" == "${ZOOM_INSTALLED_VERSION}" ]]; then
    echo "<result>Yes</result>"
else
    echo "<result>No</result>"
fi

exit 0
