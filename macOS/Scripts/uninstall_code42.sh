#!/bin/bash

code42_uninstall_app_path="/Library/Application Support/CrashPlan"
code42_uninstall_app="Uninstall.app"
code42_app="/Applications/Code42.app"


if test -d "${code42_uninstall_app_path}/${code42_uninstall_app}"; then
    echo "Open Code42 ${code42_uninstall_app}"
    open -Fn "${code42_uninstall_app_path}/${code42_uninstall_app}" &
else
    echo "Code42 ${code42_uninstall_app} not found"
    exit 1
fi

while ps aux | grep Uninstall.app | grep -v grep | awk '{print $NF}'; do
    echo "Waiting for uninstall to complete..."
    ((c++)) && ((c==12)) && break
    sleep 5
done

if [[ -d "${code42_uninstall_app_path}/${code42_uninstall_app}" ]] || [[ -d "${code42_app}" ]]; then
    echo "Code42 is still installed"
    exit 1
else
    echo "Code42 was uninstalled"
    exit 0
fi