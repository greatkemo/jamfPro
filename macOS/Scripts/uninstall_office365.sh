#!/bin/bash

office_appnames="Excel OneNote Outlook PowerPoint Word Teams OneDrive"
office_processes=$(pgrep "${office_appnames} AutoUpdate" | tr '\r\n' ' ')
office_loggedinuser=$(stat -l | awk '{print $3}')
office_containers_path="/Users/${office_loggedinuser}/Library/Containers/"
office_groupcontainers_path="/Users/${office_loggedinuser}/Library/Group Containers/"
office_containers="${office_appnames} Outlook.CalendarWidget outlook.profilemanager OneDrive.FileProvider OneDrive.FinderSync OneDriveLauncher SkyDriveLauncher Microsoft-Mashup-Container netlib.shipassertprocess errorreporting Office365ServiceV2 onenote.mac onenote.mac.shareextension openxml.excel.app"
office_preferences="${office_appnames} teams OneDriveUpdater OneDriveStandaloneUpdater office office.setupassistant outlook.databasedaemon outlook.office_reminders office.licensingV2 autoupdate2"
office_lauchdaemons="${office_appnames} OneDriveStandaloneUpdaterDaemon OneDriveUpdaterDaemon autoupdate.helper office.licensingV2.helper teams.TeamsUpdaterDaemon"
office_launchagents="${office_appnames} OneDriveStandaloneUpdater update.agent"
office_privilegedhelpertools="${office_appnames} autoupdate.helper office.licensing.helper office.licensingV2.helper"
office_pkgnames="package.Microsoft_AutoUpdate.app package.Microsoft_Excel.app package.Microsoft_OneNote.app package.Microsoft_Outlook.app package.Microsoft_PowerPoint.app package.Microsoft_Word.app package.Proofing_Tools OneDrive teams"

for i in ${office_processes}; do
    while [[ "${i}" != "" ]]; do
        pkill "${office_processes}"
        until kill -9 "${i}" >/dev/null 2>&1; do
            echo "INFO: Waiting for process ${i} to stop"
            sleep 2
            ((c++)) && ((c==10)) && break
        done
        echo "INFO: Process ${i} was stopped"
        sleep 2
        ((c++)) && ((c==10)) && break
    done
    if [[ "${i}" != "" ]]; then
        pkill Microsoft
    fi
done

for i in ${office_appnames}; do
    if [[ -e "/Applications/Microsoft ${i}.app" ]]; then
        rm -rf "/Applications/Microsoft ${i}.app"
        echo "INFO: Removed /Applications/Microsoft ${i}.app"
    elif [[ -e "/Applications/${i}.app" ]]; then
        rm -rf "/Applications/${i}.app"
        echo "INFO: Removed /Applications/${i}.app from "
    else
        echo "WARN: /Applications/Microsoft ${i}.app was not found"
    fi
done

for i in ${office_containers}; do
    if [[ -e "${office_containers_path}com.microsoft.${i}" ]]; then
        rm -rf "${office_containers_path}com.microsoft.${i}"
        echo "INFO: Removed ${office_containers_path}com.microsoft.${i}"
    else
        echo "WARN: ${office_containers_path}com.microsoft.${i} was not found"
    fi
done

for i in ms office OfficeOsfWebHost;do
    if [[ -e "${office_groupcontainers_path}UBF8T346G9.${i}" ]]; then
        rm -rf "${office_groupcontainers_path}UBF8T346G9.${i}"
        echo "INFO: Removed ${office_groupcontainers_path}UBF8T346G9.${i}"
    else
        echo "WARN: ${office_groupcontainers_path}UBF8T346G9.${i} was not found"
    fi
done

for i in ${office_preferences}; do
    if [[ -e "/Library/Preferences/com.microsoft.${i}.plist" ]]; then
        rm -rf "/Library/Preferences/com.microsoft.${i}.plist"
        echo "INFO: Removed /Library/Preferences/com.microsoft.${i}.plist"
    else
        echo "WARN: /Library/Preferences/com.microsoft.${i}.plist was not found"
    fi
done

for i in ${office_lauchdaemons}; do
    if [[ -e "/Library/LaunchDaemons/com.microsoft.${i}.plist" ]]; then
        rm -rf "/Library/LaunchDaemons/com.microsoft.${i}.plist"
        echo "INFO: Removed /Library/LaunchDaemons/com.microsoft.${i}.plist"
    else
        echo "WARN: /Library/LaunchDaemons/com.microsoft.${i}.plist was not found"
    fi
done

for i in ${office_launchagents}; do
    if [[ -e "/Library/LaunchAgents/com.microsoft.${i}.plist" ]]; then
        rm -rf "/Library/LaunchAgents/com.microsoft.${i}.plist"
        echo "INFO: Removed /Library/LaunchAgents/com.microsoft.${i}.plist"
    else
        echo "WARN: /Library/LaunchAgents/com.microsoft.${i}.plist was not found"
    fi
done

for i in ${office_privilegedhelpertools}; do
    if [[ -e "/Library/PrivilegedHelperTools/com.microsoft.${i}" ]]; then
        rm -rf "/Library/PrivilegedHelperTools/com.microsoft.${i}"
        echo "INFO: Removed /Library/PrivilegedHelperTools/com.microsoft.${i}"
    else
        echo "WARN: /Library/PrivilegedHelperTools/com.microsoft.${i} was not found"
    fi
done

if [[ -d "/Library/Application Support/Microsoft/MAU2.0" ]]; then
    rm -rf "/Library/Application Support/Microsoft/MAU2.0"
    echo "INFO: Removed /Library/Application Support/Microsoft/MAU2.0"
fi

if [[ -d "/Library/Fonts/Microsoft" ]]; then
    rm -rf "/Library/Fonts/Microsoft"
    echo "INFO: Removed /Library/Fonts/Microsoft"
fi

for i in ${office_pkgnames}; do
    answer=$(pkgutil --forget "com.microsoft.${i}")
    echo "INFO: ${answer}"
done

exit 0
