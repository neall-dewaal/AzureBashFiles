#!/bin/bash
# ===========================================================================================================
# INSTRUCTIONS:
# ===========================================================================================================
# Bash script to install the following for Debian based systems:
# -Apache2
# -MariaDB
# -PHP 7.2 and its required modules.
# -phpmyadmin
# -configures the sudo users password on first startup
# -updates the system and its packages
# ===========================================================================================================
# ===========================================================================================================
# TODO:
# ===========================================================================================================
# 1) Setup start question.
# 2) Setup import of current versions of packages since last run.
# 3) Setup check for new repository version available
# 4) Setup configuration of subshells-processes
# 5) WTF PHPMYADMIN
# 6) Setup insertion of code lines in conf files.
# 7) IonCube Install for php.
# ===========================================================================================================
# ===========================================================================================================
# DECLARE GLOBAL VARIABLES:
# ===========================================================================================================
# Directories
DirectoryPermissionRewriteLocation=/var/www/html #Specify directory for which to rewrite permissions.
OutputFileLocation=/home/neall/Output.txt #specify your output file here.
AllConf=/home/$USER/VMConfig.txt

# Get system versioning
phpCur=7.2
mariadbCur=10.3
isFirst=n

# Colours
Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red 
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

# ===========================================================================================================
# Prints the variable passed into the indicated file //
function printInput {
    strOutput=$(date '+%d/%m/%Y %H:%M:%S')
    strOutput="$strOutput $1"
    echo $strOutput >> $OutputFileLocation
}
# Set the superuser's password //
function setupUserPassword {
    echo -e "$Cyan \n Setting up Root Password... $Color_Off"
    echo -e "$Yellow \n Enter the password that will be used for the root user: $Color_Off"
    echo -e "$Yellow \n For Stratusolve this would be the same as the ssh password. $Color_Off"
    sudo passwd
    printInput "Successfully updated Root password"
}
#Login as superuser
function loginSudo {
    currentUser=$USER
    echo -e "$Cyan \n logging in as root... $Color_Off"
    su
    printInput "Successfully logged in as root"
}
# Update packages and Upgrade system //
function UpdateSys {
    echo -e "$Cyan \n Updating System... $Color_Off"
    sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoremove -y
    printInput "Successfully updated all packages, dependencies and distributions."
}
# Install Apache //
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
    echo -e "$Yellow \n Installing MariaDB $Color_Off"
    echo -e "$Red \n FOR THE FOLLOWING YOU HAVE TO PRESS 'ENTER' WHENEVER PROMPTED FOR AN INPUT! $Color_Off"
    echo -e "$Red \n ENTER 'YES' IF YOU UNDERSTAND. $Color_Off"
    read -p ""  answer
    while [[ $answer != 'YES' ]]
    do
    echo -e "$Red \n YOU DID NOT UNDERSTAND... PLEASE ENTER 'YES' IF YOU UNDERSTAND! $Color_Off"
    read -p ""  answer
    done
    sudo apt install mariadb-server -y
    sudo systemctl stop mariadb.service
    sudo systemctl start mariadb.service
    sudo systemctl enable mariadb.service
    printInput "Successfully installed MariaDb"
}
function WriteDatabasePermissions {
    echo -e "$Cyan \n Configuring Database $Color_Off"
    #mysql -u root --password="hVx?N8ZP}*7X"
    mysql -u root -phVx?N8ZP}*7X<<-EOF
use mysql;
UPDATE user SET Password=PASSWORD('hVx?N8ZP}*7X') WHERE User='root';
DELETE FROM user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
update user set plugin='mysql_native_password' where User='root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF
    printInput "Successfully installed MariaDb"
}
# Install PHP //
function InstallPHP {
    echo -e "$Cyan \n Installing PHP $Color_Off"
    sudo apt install php php-gettext php-cli php-common php-mbstring libapache2-mod-php php-mysql php-pear -y
    sudo a2enconf
    printInput "Successfully installed PHP"
}
#Install phpmyadmin
function InstallMyAdmin {
    echo -e "$Cyan \n Getting debian-sys-maint password $Color_Off"
    while read string
    do
    #Test the version of php
    if [[ $string == *"password"* ]]; then
        debPasswd=$(echo $string | cut -d' ' -f 3)
        echo $debPasswd
    fi
    #Test the version of MariaDB
    done < /etc/mysql/debian.cnf
    mysql -u root -e "UPDATE mysql.user SET Password = password('$debPasswd') WHERE User = 'debian-sys-maint';FLUSH PRIVILEGES;"
    echo -e "$Cyan \n Installing phpMyAdmin $Color_Off"
    sudo apt install phpmyadmin -y
    sudo phpenmod mbstring
    #-phVx?N8ZP}*7X
    ## Here the user needs to enter their DB password for their account
    #CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY 'hVx?N8ZP}*7X';
    #UPDATE user SET Password=PASSWORD('hVx?N8ZP}*7X') WHERE User='phpmyadmin';
    #update user set plugin='mysql_native_password' where User='phpmyadmin';
    #show grants for 'phpmyadmin'@'localhost';
    #SELECT user,authentication_string,plugin,host FROM mysql.user;
    #GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost';
    #GRANT ALL ON *.* TO 'pma'@'%' identified by 'hVx?N8ZP}*7X';
    ## The debian-sys-maint@localhost password does not match those 
    ## in the config
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
    sudo killall -u ss_admin; sleep 2; sudo usermod -d /var/www/html ss_admin &
    printInput "Successfully updated the default login directory."
}

#WELCOME PROMPT
echo -e "$Green Hi! Welcome to the setup wizard! $Color_Off"
echo -e "$Green Here we will set up your machine. $Color_Off"
echo -e "$Green We will now present you with a list of questions to speed up the configuration. $Color_Off"
echo -e "$Green Are you ready? [y/n]:"
read -rsp $'Press any key to continue...' -n1 key
echo -e "$Green Great! Here we go. $Color_Off"
echo -e "$Red Is this the first time running this machine? [y/n] $Color_Off"
read -rsp "" -n1 key
if [[ $key == y ]]; then
    isFirst=y
    echo -e "\n"
fi
echo -e ""
while read string
do
    echo $string
    #Test the version of php
    if [[ $string == *"php"* ]]; then
        SUBSTR=$(echo $string | cut -d'=' -f 2)
    fi
    #Test the version of MariaDB
    if [[ $string == *"mariadb"* ]]; then
        SUBSTR=$(echo $string | cut -d'=' -f 2)
    fi
done < VMConfig.txt

# Here we define the functions to run if it is the first time.
if [[ $isFirst == y ]]; then
    #UpdateSys
    #setupUserPassword
    #InstallApache
    #InstallPHP
    #InstallMaria
    #RestartServer
    #InstallMyAdmin
    #RestartServer
    # Select apache2 for install
    WriteDatabasePermissions
    #RestartServer
    #WritePermissions
    # Which conf(s) do you want to enable (wildcards ok)?

fi