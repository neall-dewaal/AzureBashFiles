#!/bin/bash

# Colours
Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red 
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

#Global variables
declare -A CheckExists
CheckExists["CustomScripts"]="false"
CheckExists["Confs"]="false"
FirstRun=/etc/pam.d/custom-scripts/FirstRun.txt
AllConf=/etc/pam.d/custom-scripts/VMConfig.txt

CommandToPass='none'
usr='root'
isConfigure=y


if [ ! -d "/etc/pam.d/custom-scripts" ]; then
    isConfigure=n
    CommandToPass='All'
fi

function SystemVersionChecks {
    while read string
    do
        #echo $string
        #Test the version of php
        if [[ $string == *"php"* ]]; then
            phpInstalledVer=$(echo $string | cut -d'=' -f 2)
        fi
        
        #Test the version of MariaDB
        if [[ $string == *"mariadb"* ]]; then
            mariaInstalledVer=$(echo $string | cut -d'=' -f 2)
        fi

        if [[ $string == *"username"* ]]; then
            usr=$(echo $string | cut -d'=' -f 2)
        fi
    done < $AllConf
    if [[ $usr == 'root' ]]; then
        echo "User is not configured."
    fi

    # The outcome of the php versioning check
    phpAvailableVer=$(apt-cache madison php | cut -d':' -f2 | cut -d'+' -f1)
    if [[ $phpAvailableVer != $phpInstalledVer ]]
    then
        echo "A new version of PHP is available ($phpInstalledVer=>$phpAvailableVer)."
    fi
    #mariadb version

}
# Checks the configuration of the system to see if all configs are matched.
function SystemFirstRunCheck {
    # Check for the files in the /etc/pam.d/custom-scripts directory
    if [ -d "/etc/pam.d/custom-scripts" ]; then
        AllFilesExists="true"
        if [ ! -f "/etc/pam.d/custom-scripts/AzureFirstInstall.sh" ]; then
            echo "AzureFirstInstall does not exist in Directory."
            AllFilesExists="false"
        fi
        if [ ! -f "/etc/pam.d/custom-scripts/FirstRun.txt" ]; then
            echo "FirstRun does not exist in Directory."
            AllFilesExists="false"
        fi
        if [ ! -f "/etc/pam.d/custom-scripts/VMConfig.txt" ]; then
            echo "VMConfig does not exist in Directory."
            AllFilesExists="false"
        fi
        if [ ! -f "/etc/pam.d/custom-scripts/stopBash.txt" ]; then
            echo "stopBash does not exist in Directory."
            AllFilesExists="false"
        fi
        if [ ! -f "/etc/pam.d/custom-scripts/Output.txt" ]; then
            echo "Output does not exist in Directory."
            AllFilesExists="false"
        fi
        if [ ! -f "/etc/pam.d/custom-scripts/chPermOwn.sh" ]; then
            echo "chPermOwn does not exist in Directory."
            AllFilesExists="false"
        fi
        if [ ! -f "/etc/pam.d/custom-scripts/StratusolveConfigVM.sh" ]; then
            echo "StratusolveConfigVM does not exist in Directory."
            AllFilesExists="false"
        fi

        if [[ $AllFilesExists == 'true' ]]; then
            CheckExists['CustomScripts']='true'
        fi
    fi

    # Check if config files are the same
    ConfsMatch="true"
    old=/home/$usr/config.inc.php
    new=/usr/share/phpmyadmin/config.inc.php
    cmp --silent $old $new || ConfsMatch="false"
    if [[ $ConfsMatch == "false" ]]; then
        echo "config.inc.php does not match."
    fi
    old1=/home/$usr/phpmyadmin.conf
    new1=/etc/apache2/conf-enabled/phpmyadmin.conf
    cmp --silent $old1 $new1 || ConfsMatch="false"
    if [[ $ConfsMatch == "false" ]]; then
        echo "phpmyadmin.conf does not match."
    fi
    if [[ $ConfsMatch == "true" ]]; then
        CheckExists["Confs"]="true"
    fi
    #TO REMOVE
    CheckExists["Confs"]="true"

    # Sets the command to pass if all conditions are met.
    AllConditionsMet='true'
    for K in "${!CheckExists[@]}"
    do
        if [[ ${CheckExists[$K]} == "false" ]]; then
            AllConditionsMet='false'
        fi
    done
    if [[ $AllConditionsMet == "false" ]]; then
        CommandToPass='All'
    else
        CommandToPass='none'
    fi
    read fileLine < $FirstRun
        chrlen=${#fileLine}
        if [ $chrlen -gt 0 ]
        then
            isConfigure=y
    fi
}

if [[ $isConfigure == n ]]; then
    ./AzureFirstInstall.sh $CommandToPass
else
    cd $WorkingDirectory
    SystemVersionChecks
    SystemFirstRunCheck
    ./AzureFirstInstall.sh $CommandToPass
fi
