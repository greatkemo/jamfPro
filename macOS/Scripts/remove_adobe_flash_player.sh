#!/bin/bash

# This script is meant for the purpose of removing the PPAPI and NPAPI Adobe FlashPlayer plugins
# This in response to an Adobe FlashPlayer critical vulnerability (CVE-2018-4878) which exists in
# Adobe Flash Player 28.0.0.137 and earlier versions.
# More details here: https://helpx.adobe.com/security/products/flash-player/apsa18-01.html
# The information used to compile this script can be found at:
# https://www.adobe.com/devnet/flashplayer/articles/flash_player_admin_guide.html
#
# [[USE AT YOUR OWN RISK]]
# Written by: Kamal Taynaz
# Senior Systems Engineer
# Carnegie Mellon University Qatar

echo "`date` INF: Uninstall Script has started"
sleep 1
# Set the Update to default values in mms.cfg
echo "`date` INF: Looking for mms.cfg"
if [[ -e "/Library/Application Support/Macromedia/mms.cfg" ]]; then
  echo "`date` INF: mms.cfg was found"
  sleep 1
  echo "`date` INF: Eidting mms.cfg"
  sleep 1
  echo "`date` INF: Make AutoUpdateDisable = 0"
  sleep 1
  echo "AutoUpdateDisable=0" > "/Library/Application Support/Macromedia/mms.cfg"
  sleep 1
  echo "`date` INF: Make SilentAutoUpdateEnable = 0"
  sleep 1
  echo "SilentAutoUpdateEnable=0" >> "/Library/Application Support/Macromedia/mms.cfg"
else
  echo "`date` WAR: mms.cfg was not found"
  sleep 1
fi

# Run launchctl unload tp unload the SAU daemon
echo "`date` INF: Looking for Launch Daemons"
sleep 1
daemon=$(launchctl list | grep adobe | awk '{print $3}')
if [[ "$daemon" =  "com.adobe.fpsaud" ]]; then
  echo "`date` INF: Launch Daemon $daemon was found"
  sleep 1
  echo "`date` INF: Unloading $daemon now"
  sleep 1
  launchctl unload "/Library/LaunchDaemons/com.adobe.fpsaud.plist"
  sleep 2
  if [[ $(launchctl list | grep adobe | awk '{print $3}') == "$daemon" ]]; then
    echo "`date` ERR: $daemon Launch Daemon failed to unload, please try again"
    exit 1
  else
    echo "`date` INF: $daemon was unloaded successfully"
    sleep 1
  fi
fi

# Delete the following if found
echo "`date` INF: Looking for Flash Player.plugin"
sleep 1
if [[ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]]; then
  echo "`date` INF: Flash Player.plugin found"
  sleep 1
  echo "`date` INF: Removing Flash Player.plugin"
  sleep 1
  rm -rf "/Library/Internet Plug-Ins/Flash Player.plugin"
  if [[ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]]; then
    echo "`date` ERR: Flash Player.plugin Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: Flash Player.plugin was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: Flash Player.plugin was not found"
  sleep 1
fi
echo "`date` INF: Looking for flashplayer.xpt"
sleep 1
if [[ -e "/Library/Internet Plug-Ins/flashplayer.xpt" ]]; then
  echo "`date` INF: flashplayer.xpt found"
  sleep 1
  echo "`date` INF: Removing flashplayer.xpt"
  sleep 1
  rm -rf "/Library/Internet Plug-Ins/flashplayer.xpt"
  if [[ -e "/Library/Internet Plug-Ins/flashplayer.xpt" ]]; then
    echo "`date` ERR: flashplayer.xpt Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: flashplayer.xpt was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: flashplayer.xpt was not found"
  sleep 1
fi
echo "`date` INF: Looking for PepperFlashPlayer.plugin"
if [[ -e "/Library/Internet Plug-Ins/PepperFlashPlayer/PepperFlashPlayer.plugin" ]]; then
  echo "`date` INF: PepperFlashPlayer.plugin found"
  sleep 1
  echo "`date` INF: Removing PepperFlashPlayer.plugin"
  sleep 1
  rm -rf "/Library/Internet Plug-Ins/PepperFlashPlayer/PepperFlashPlayer.plugin"
  if [[ -e "/Library/Internet Plug-Ins/PepperFlashPlayer/PepperFlashPlayer.plugin" ]]; then
    echo "`date` ERR: PepperFlashPlayer.plugin Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: PepperFlashPlayer.plugin was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: PepperFlashPlayer.plugin was not found"
  sleep 1
fi
echo "`date` INF: Looking for manifest.json"
sleep 1
if [[ -e "/Library/Internet Plug-Ins/PepperFlashPlayer/manifest.json" ]]; then
  echo "`date` INF: manifest.json found"
  sleep 1
  echo "`date` INF: Removing manifest.json"
  sleep 1
  rm -rf "/Library/Internet Plug-Ins/PepperFlashPlayer/manifest.json"
  if [[ -e "/Library/Internet Plug-Ins/PepperFlashPlayer/manifest.json" ]]; then
    echo "`date` ERR: manifest.json Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: manifest.json was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: manifest.json was not found"
  sleep 1
fi
echo "`date` INF: Looking for com.adobe.fpsaud.plist"
sleep 1
if [[ -e "/Library/LaunchDaemons/com.adobe.fpsaud.plist" ]]; then
  echo "`date` INF: com.adobe.fpsaud.plist found"
  sleep 1
  echo "`date` INF: Removing com.adobe.fpsaud.plist"
  sleep 1
  rm -rf "/Library/LaunchDaemons/com.adobe.fpsaud.plist"
  if [[ -e "/Library/LaunchDaemons/com.adobe.fpsaud.plist" ]]; then
    echo "`date` ERR: com.adobe.fpsaud.plist Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: com.adobe.fpsaud.plist was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: com.adobe.fpsaud.plist was not found"
  sleep 1
fi
echo "`date` INF: Looking for FPSAUConfig.xml"
sleep 1
if [[ -e "Library/Application Support/Adobe/Flash Player Install Manager/FPSAUConfig.xml" ]]; then
  echo "`date` INF: FPSAUConfig.xml found"
  sleep 1
  echo "`date` INF: Removing FPSAUConfig.xml"
  sleep 1
  rm -rf "Library/Application Support/Adobe/Flash Player Install Manager/FPSAUConfig.xml"
  if [[ -e "Library/Application Support/Adobe/Flash Player Install Manager/FPSAUConfig.xml" ]]; then
    echo "`date` ERR: FPSAUConfig.xml Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: FPSAUConfig.xml was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: FPSAUConfig.xml was not found"
  sleep 1
fi
echo "`date` INF: Looking for fpsaud"
sleep 1
if [[ -e "/Library/Application Support/Adobe/Flash Player Install Manager/fpsaud" ]]; then
  echo "`date` INF: fpsaud found"
  sleep 1
  echo "`date` INF: Removing fpsaud"
  sleep 1
  rm -rf "/Library/Application Support/Adobe/Flash Player Install Manager/fpsaud"
  if [[ -e "/Library/Application Support/Adobe/Flash Player Install Manager/fpsaud" ]]; then
    echo "`date` ERR: fpsaud Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: fpsaud was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: fpsaud was not found"
  sleep 1
fi

# Forget Package Receipt
echo "`date` INF: Search and remove FlashPlayer Receipts"
sleep 1
find /Library/Receipts -type f -name *FlashPlayer* -maxdepth 1 -exec rm -rf {} \;
pkgutil --packages | grep com.adobe.pkg.FlashPlayer >/dev/null
if [[ $? = 0 ]]; then
  echo "`date` INF: Forgetting com.adobe.pkg.FlashPlayer"
  sleep 1
  pkgutil --force --forget com.adobe.pkg.FlashPlayer >/dev/null 2>&1
elif [[ $? = 1 ]]; then
  echo "`date` WAR: com.adobe.pkg.FlashPlayer Receipt not found"
  sleep 1
fi

# Remove The Flash Player PreferencePane
echo "`date` INF: Removing PreferencePane entry"
sleep 1
echo "`date` INF: Looking for Flash Player.prefPane"
sleep 1
if [[ -e "/Library/PreferencePanes/Flash Player.prefPane" ]]; then
  echo "`date` INF: Flash Player.prefPane found"
  sleep 1
  echo "`date` INF: Removing Flash Player.prefPane"
  sleep 1
  rm -rf "/Library/PreferencePanes/Flash Player.prefPane"
  if [[ -e "/Library/PreferencePanes/Flash Player.prefPane" ]]; then
    echo "`date` ERR: Flash Player.prefPane Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: Flash Player.prefPane was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: Flash Player.prefPane was not found"
  sleep 1
fi

# Search user profiles ($p) for com.apple.systempreferences.plist and delete key
echo "`date` INF: Searing user profiles for plist"
for p in $(ls /Users); do
  if [[ -e "/Users/$p/Library/Preferences/com.apple.systempreferences.plist" ]]; then
    echo "`date` INF: Found com.apple.systempreferences.plist for user $p"
    sleep 1
    echo "`date` INF: Edit com.apple.systempreferences.plist for user $p"
    sleep 1
    defaults delete "/Users/$p/Library/Preferences/com.apple.systempreferences" "com.adobe.preferences.flashplayer" >/dev/null 2>&1
  fi
done

# Remove Flash Player Install Manager app
echo "`date` INF: Looking for Adobe Flash Player Install Manager.app"
sleep 1
if [[ -e "/Applications/Utilities/Adobe Flash Player Install Manager.app" ]]; then
  echo "`date` INF: Adobe Flash Player Install Manager.app found"
  sleep 1
  echo "`date` INF: Removing Adobe Flash Player Install Manager.app"
  sleep 1
  rm -rf "/Applications/Utilities/Adobe Flash Player Install Manager.app"
  if [[ -e "/Applications/Utilities/Adobe Flash Player Install Manager.app" ]]; then
    echo "`date` ERR: Adobe Flash Player Install Manager.app Could not be removed. Please try again"
    exit 1
  else
    echo "`date` INF: Adobe Flash Player Install Manager.app was removed successfully"
    sleep 1
  fi
else
  echo "`date` WAR: Adobe Flash Player Install Manager.app was not found"
  sleep 1
fi

echo "`date` INF: Uninstall Script has finished"

exit 0
