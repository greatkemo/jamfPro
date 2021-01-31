#!/bin/bash

acrobat_app="/Applications/Adobe Acrobat DC/Adobe Acrobat.app"
acrobat_uninstaller="/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/Library/LaunchServices/com.adobe.Acrobat.RemoverTool"

if pgrep AdobeAcrobat >/dev/null; then
  echo "INFO: Acrobat is running"
  echo "INFO: Quitting Acrobat App"
  pkill AdobeAcrobat  >/dev/null 2>&1
else
  echo "INFO: Acrobat is not running"
fi

echo "INFO: Path to Remver Tool is ${acrobat_uninstaller}"
echo "INFO: Path to Acrobat App is ${acrobat_app}"
echo "INFO: Removing app..."
"${acrobat_uninstaller}" "${acrobat_app}" >/dev/null 2>&1

sleep 2

if [[ ! -d "${acrobat_app}" ]]; then
  echo "SUCCESS: Acrobat was removed"
  exit 0
else
  echo "ERROR: Acrobat was not removed"
  exit 1
fi