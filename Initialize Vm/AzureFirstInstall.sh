#!/bin/bash

#######################################
# Bash script to install the following for Debian based systems:
# -Apache2
# -MariaDB
# -PHP 7.2 and its required modules.
# -phpmyadmin
# -configures the sudo users password on first startup
# -updates the system and its packages
#######################################
# SETUP:
# 1) Setup start question.
# 2) Setup import of current versions of packages since last run.
# 3) Setup check for new repository version available
# 4) Setup configuration of subshells-processes
# 5) WTF PHPMYADMIN
# 6) Setup insertion of code lines in conf files.
# 7) IonCube Install for php.
DirectoryPermissionRewriteLocation=/var/www/html #Specify directory for which to rewrite permissions.
OutputFileLocation=/home/ss_admin/Output.txt #specify your output file here.
#AllConf=/var/www/html/VMConfig.txt

#Get sytem version variables.
phpCur=7.2
mariadbCur=10.3

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red 
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

# Waits for user to press any key before continueing.
#Function: Prints the variable passed into the indicated file
function printInput {
    strOutput=$(date '+%d/%m/%Y %H:%M:%S')
    strOutput="$strOutput $1"
    echo $strOutput >> $OutputFileLocation
}
#Set the superuser's password
function setupUserPassword {
    echo -e "$Cyan \n Setting up Root Password... $Color_Off"
    sudo passwd
    printInput "Successfully updated Root password"
}
#Login as superuser
function loginSudo {
    currentUser=$USER
    echo -e "$Cyan \n logging in as root... $Color_Off"
    echo 'sudo -n su'
    printInput "Successfully logged in as root"
}
# Update packages and Upgrade system
function UpdateSys {
    echo -e "$Cyan \n Updating System... $Color_Off"
    sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoremove -y
    printInput "Successfully updated all packages, dependencies and distributions."
}
# Install Apache
function InstallApache {
    echo -e "$Cyan \n Installing Apache2 $Color_Off"
    sudo apt-get install apache2 -y
    sudo ufw allow in "Apache Full"
    printInput "Successfully installed Apache2"
}
#Install MariaDb
function InstallMaria {
    echo -e "$Cyan \n Installing MariaDb $Color_Off"
    sudo apt-get install software-properties-common -y
    echo -e "$Yellow \n Adding keys $Color_Off"
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    echo -e "$Yellow \n Adding repository $Color_Off"
    sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://ftp.utexas.edu/mariadb/repo/10.3/ubuntu bionic main'
    echo -e "$Yellow \n Updating $Color_Off"
    sudo apt update -y
    echo -e "$Yellow \n Adding keys and repository $Color_Off"
    sudo mysql_secure_installation
    echo -e "$Yellow \n Install $Color_Off"
    sudo apt install mariadb-server -y #create expect for this
    sudo systemctl stop mariadb.service
    sudo systemctl start mariadb.service
    sudo systemctl enable mariadb.service
    echo -e "$Yellow \n Logging In $Color_Off"
    mysql -u root -p #create expect for this
    ##After this none of these are executed
    use mysql;
    update user set plugin='mysql_native_password' where User='root';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
    flush privileges;
    \q
    printInput "Successfully installed MariaDb"
}
# Install PHP
function InstallPHP {
    echo -e "$Cyan \n Installing PHP $Color_Off"
    sudo apt install php php-cgi php-cli php-common php-mbstring libapache2-mod-php php-mysql php-pear -y
    sudo a2enconf
    printInput "Successfully installed PHP"
}
#Install phpmyadmin
function InstallMyAdmin {
    echo -e "$Cyan \n Installing phpMyAdmin $Color_Off"
    sudo apt install phpmyadmin -y
    mysql -u root -p
    ## Here the user needs to enter their DB password for their account
    ## The debian-sys-maint@localhost password does not match those 
    ## in the config

    use mysql;
    update user set plugin='mysql_native_password' where User='phpmyadmin';
    GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost';
    flush privileges;
    exit;
    printInput "Successfully installed phpmyadmin"
}
# Restart WebServer
function RestartServer {
    echo -e "$Cyan \n Restarting Apache $Color_Off"
    sudo service apache2 restart
    printInput "Successfully restarted the Apache server"
}
#Change permissions
function WritePermissions {
    echo -e "$Cyan \n Changing default permissions of files $Color_Off"
    sudo adduser ss_admin www-data
    sudo chown -R ss_admin:www-data /var/www/html 
    find /var/www/html -type d -exec chmod 755 {} +
    find /var/www/html -type f -exec chmod 775 {} +
    sudo chmod ug+s /var/www/html
    echo -e "$Green \n Permissions have been set $Color_Off"
    printInput "Successfully updated the file permissions of /var/www/html."
}
#Change default landing directory on login
ChangeDefaultDir () {
    echo -e "$Cyan \n Installing default landing directory $Color_Off"
    sudo su {
        sudo killall -u ss_admin; sleep 2; sudo usermod -d /var/www/html ss_admin &    
    }
    sudo killall -u ss_admin; sleep 2; sudo usermod -d /var/www/html ss_admin &
    printInput "Successfully updated the default login directory."
}

#WELCOME PROMPT
echo -e "$Green Hi! Welcome to the setup wizard! $Color_Off"
echo -e "$Green Here we will set up your machine. $Color_Off"
echo -e "$Green We will now present you with a list of questions to speed up the configuration. $Color_Off"
echo -en "$Green Are you ready? [y/n]:"
read -rsp $'Press any key to continue...\n' -n1 key
echo -e "$Green Great! Here we go. $Color_Off"
#setupUserPassword
#loginSudo

#UpdateSys
#InstallApache
#InstallMaria
#InstallPHP
#InstallMyAdmin
#RestartServer
WritePermissions
#ChangeDefaultDir
echo 'hey'

