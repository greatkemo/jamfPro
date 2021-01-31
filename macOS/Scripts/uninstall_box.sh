#!/bin/bash

box_drive_app="/Applications/Box.app"
"/Library/Application Support/Box/uninstall_box_drive_r"

if [[ -d "${box_drive_app}" ]]; then
    for p in $(ps aux | grep "Box.app" | grep -v grep | awk '{print $2}' | tr '\r\n' ' '); do
        kill -9 "${p}" >/dev/null 2>&1
    done
    /Library/Application\ Support/Box/uninstall_box_drive_r >/dev/null 2>&1
    /Library/Application\ Support/Box/Uninstaller >/dev/null 2>&1
    rm -f /Users/*/Library/Preferences/com.box.desktop.installer.plist
    rm -f /Users/*/Library/Preferences/com.box.desktop.ui.plist
    rm -f /Users/*/Library/Preferences/com.box.desktop.plist
fi


