#!/bin/bash

# Colours
Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red 
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

isFirst=y
StopBashFile=/etc/pam.d/custom-scripts/FirstRun.txt
read fileLine < $StopBashFile
    chrlen=${#fileLine}
    if [ $chrlen -gt 0 ]
    then
        isFirst=n
fi

if [ $isFirst == y ]
then
    #WELCOME PROMPT
    echo -e "$Green Hi! Welcome to the setup wizard! $Color_Off"
    echo -e "$Green Here we will set up your machine. $Color_Off"
    echo -e "$Green We will now present you with a list of questions to speed up the configuration. $Color_Off"
    echo -e "$Green Are you ready? [y/n]:"
    read -rsp $'Press any key to continue...' -n1 key
    echo -e "$Green Great! Here we go. $Color_Off"
    read -p "Is this the first time running this machine? [y/n]" key
    if [[ $key == y ]]; then
        isFirst=y
    fi
    read -p "What is the username used to SSH into the VM: " username
    read -rsp "What is the password used to SSH into the VM: " password
    read -rsp "Please repeat the password: " reppassword
    while [[ $password != $reppassword ]];
    do
        echo -e "$Red Your password do not match! $Color_Off"
        read -rsp "What is the password used to SSH into the VM: " password
        read -rsp "Please repeat the password: " reppassword
    done
    sudo chmod -R 777 /etc/pam.d
    sudo mkdir /etc/pam.d/custom-scripts
    sudo mv /home/$username/chPermOwn.sh /etc/pam.d/custom-scripts
    sudo mv /home/$username/Output.txt /etc/pam.d/custom-scripts
    sudo mv /home/$username/stopBash.txt /etc/pam.d/custom-scripts
    sudo mv /home/$username/VMConfig.txt /etc/pam.d/custom-scripts
    sudo chmod +x /etc/pam.d/custom-scripts/chPermOwn.sh
    sudo cp /home/$username/CheckFirstRun.sh /etc/pam.d/custom-scripts/CheckFirstRun.sh
    sudo chmod +x /etc/pam.d/custom-scripts/CheckFirstRun.sh
    sudo mv /home/$username/AzureFirstInstall.sh /etc/pam.d/custom-scripts
    sudo chmod +x /etc/pam.d/custom-scripts/AzureFirstInstall.sh
    sudo mv /home/$username/FirstRun.txt /etc/pam.d/custom-scripts
    cd /etc/pam.d/custom-scripts
    sudo ./AzureFirstInstall.sh $username $password
    strOutput="Done"
    echo $strOutput >> /etc/pam.d/custom-scripts/FirstRun.txt
    echo -e "$Cyan \n Installing default landing directory $Color_Off"
    sudo su <<EOF
killall -u $username; sleep 2; usermod -d /var/www/html $username &
EOF
else
    ./etc/pam.d/custom-scripts/chPermOwn.sh
fi