#!/bin/bash

bitdefender_uninstall_app_path="/Library/Bitdefender/AVP/Uninstaller/"
bitdefender_uninstall_app="EndpointSecurityforMacUninstaller.app"
bitdefender_app="/Library/Bitdefender/AVP/EndpointSecurityforMac.app"


if test -d "${bitdefender_uninstall_app_path}/${bitdefender_uninstall_app}"; then
    echo "Open Bitdefender ${bitdefender_uninstall_app}"
    open -Fn "${bitdefender_uninstall_app_path}/${bitdefender_uninstall_app}" &
else
    echo "Bitdefender ${bitdefender_uninstall_app} not found"
    exit 1
fi

while ps aux | grep EndpointSecurityforMacUninstaller.app | grep -v grep | awk '{print $NF}'; do
    echo "Waiting for uninstall to complete..."
    ((c++)) && ((c==12)) && break
    sleep 5
done

if [[ -d "${bitdefender_uninstall_app_path}/${bitdefender_uninstall_app}" ]] || [[ -d "${bitdefender_app}" ]]; then
    echo "Bitdefender is still installed"
    exit 1
else
    echo "Bitdefender was uninstalled"
    exit 0
fi