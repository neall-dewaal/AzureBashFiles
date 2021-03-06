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

# Get system versioning
phpCur=7.2
mariadbCur=10.3
isFirst=y

# Colours
Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red 
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

# ===========================================================================================================
# Prints the variable passed into the indicated file 
function printInput {
    strOutput=$(date '+%d/%m/%Y %H:%M:%S')
    strOutput="$strOutput $1"
    echo $strOutput >> $OutputFileLocation
}
# Set the superuser's password //
function setupUserPassword {
    echo -e "$Cyan \n Setting up Root Password... $Color_Off"
    printf "$passwd\n$passwd" | sudo passwd
    printInput "Successfully updated Root password"
}
# Update packages and Upgrade system //
function UpdateSys {
    echo -e "$Cyan \n Updating System... $Color_Off"
    sudo ufw allow in "openSSH"
    sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoremove -y
    set-timezone Africa/Johannesburg
    printInput "Successfully updated all packages, dependencies and distributions."
}
# Install Apache //
function InstallApache {
    echo -e "$Cyan \n Installing Apache2 $Color_Off"
    sudo apt-get install apache2 -y
    sudo systemctl stop apache2.service
    sudo systemctl start apache2.service
    sudo systemctl enable apache2.service
    sudo ufw allow in "Apache Full"
    sudo ufw enable -y
    printInput "Successfully installed Apache2"
}
#Install MariaDb
function InstallMaria {
    echo -e "$Cyan \n Installing MariaDb $Color_Off"
    sudo apt-get install software-properties-common -y
    # here
    echo -e "$Yellow \n Adding keys $Color_Off"
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    echo -e "$Yellow \n Adding repository $Color_Off"
    sudo add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu bionic main'
    echo -e "$Yellow \n Updating $Color_Off"
    sudo apt update -y
    echo -e "$Yellow \n Installing MariaDB $Color_Off"
    sudo apt-get install debconf-utils -y
    sudo export DEBIAN_FRONTEND=noninteractive
    sudo export passwd
    echo mariadb-server mysql-server/root_password password $passwd | sudo debconf-set-selections
    echo mariadb-server mysql-server/root_password_again password $passwd | sudo debconf-set-selections
    sudo apt -y install mariadb-server mariadb-client
    sudo systemctl stop mariadb.service
    sudo systemctl start mariadb.service
    sudo systemctl enable mariadb.service
    printInput "Successfully installed MariaDb"
}
#Clean and secure the database
function WriteDatabasePermissions {
    echo -e "$Cyan \n Configuring Database $Color_Off"
    #UPDATE user SET password = PASSWORD($passwd) WHERE user = 'root';
    mysql -u root -p$passwd<<-EOF
use mysql;
DELETE FROM user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
CREATE USER ${usr} IDENTIFIED BY '${passwd}';
FLUSH PRIVILEGES;
update user set plugin='mysql_native_password' where User='root';
update user set plugin='mysql_native_password' where User='${usr}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO '${usr}'@'%';
FLUSH PRIVILEGES;
EOF
    printInput "Successfully configured database"
}
# Install PHP //
function InstallPHP {
    echo -e "$Cyan \n Installing PHP $Color_Off"
    sudo apt-get install -y php php-tcpdf php-cgi php-mysqli php-cli php-pear php-mbstring php-gettext libapache2-mod-php php-common php-phpseclib php-mysql php-curl
    printInput "Successfully installed PHP"
}
#Install phpmyadmin
function InstallMyAdmin {
    #echo -e "$Cyan \n Getting debian-sys-maint password $Color_Off"
    echo -e "$Cyan \n Installing phpMyAdmin: $Color_Off"
    echo -e "$Yellow \n Downloading archive: $Color_Off"
    export VER="4.8.5"
    sudo apt-get install -y wget
    cd /tmp
    wget https://files.phpmyadmin.net/phpMyAdmin/${VER}/phpMyAdmin-${VER}-english.tar.gz
    echo -e "$Yellow \n Extracting Archive: $Color_Off"
    tar xvf phpMyAdmin-${VER}-english.tar.gz
    rm *.tar.gz
    sudo mv phpMyAdmin-* /usr/share/phpmyadmin
    echo -e "$Yellow \n Create config files: $Color_Off"
    sudo mkdir -p /var/lib/phpmyadmin/tmp
    sudo chown -R www-data:www-data /var/lib/phpmyadmin
    sudo mkdir /etc/phpmyadmin/
    sudo cp /home/$usr/config.inc.php /usr/share/phpmyadmin/config.inc.php
    sudo cp /home/$usr/phpmyadmin.conf /etc/apache2/conf-enabled/phpmyadmin.conf
    sudo systemctl restart apache2
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
    cd /etc/pam.d
    sed -i '53i\session     optional    pam_exec.so quiet /etc/pam.d/custom-scripts/StratusolveConfigVM.sh\' sshd
    #echo "session     optional    pam_exec.so quiet /etc/pam.d/custom-scripts/StratusolveConfigVM.sh" >> /etc/pam.d/sshd
    #sudo chmod -R 774 /etc/pam.d/custom-scripts
    sudo adduser $usr www-data
    sudo chown -R www-data:www-data /var/www/html
    find /var/www/html -type d -exec chmod 775 {} +
    find /var/www/html -type f -exec chmod 775 {} +
    sudo chmod ug+s /var/www/html
    sudo chown -R www-data:www-data $DirectoryPermissionRewriteLocation
    sudo chmod -R 775 $DirectoryPermissionRewriteLocation
    echo -e "$Green \n Permissions have been set $Color_Off"
    printInput "Successfully updated the file permissions of /var/www/html."
}
#Change default landing directory on login
ChangeDefaultDir () {
    echo -e "$Cyan \n Installing default landing directory $Color_Off"
    sudo su <<EOF
killall -u $usr; sleep 2; usermod -d /var/www/html $usr &
EOF
    printInput "Successfully updated the default login directory."
}
function startupScript {
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
    # Here we define the functions to run if it is the first time.
    read -p "What is the username used to SSH into the VM: " username
    read -rsp "What is the password used to SSH into the VM: " password
    read -rsp "\nPlease repeat the password: " reppassword
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
    sudo cp /home/$username/StratusolveConfigVM.sh /etc/pam.d/custom-scripts/StratusolveConfigVM.sh
    sudo chmod +x /etc/pam.d/custom-scripts/StratusolveConfigVM.sh
    sudo cp /home/$username/AzureFirstInstall.sh /etc/pam.d/custom-scripts/AzureFirstInstall.sh
    sudo chmod +x /etc/pam.d/custom-scripts/AzureFirstInstall.sh
    sudo mv /home/$username/FirstRun.txt /etc/pam.d/custom-scripts
    usr=$username
    passwd=$password
}

DirectoryPermissionRewriteLocation=/var/www/html #Specify directory for which to rewrite permissions.
OutputFileLocation=/etc/pam.d/custom-scripts/Output.txt #specify your output file here.
AllConf=/etc/pam.d/custom-scripts/VMConfig.txt
StopBashFile=/etc/pam.d/custom-scripts/FirstRun.txt

case "$1" in
    All) echo "Initializing Machine:"
         startupScript
         UpdateSys
         setupUserPassword
         InstallApache
         InstallPHP
         InstallMaria
         InstallMyAdmin
         RestartServer
         WriteDatabasePermissions
         WritePermissions
         RestartServer
         echo "Done" >> /etc/pam.d/custom-scripts/FirstRun.txt
         echo "username=$usr" >> /etc/pam.d/custom-scripts/VMConfig.txt
         cd /home/$usr
         sudo rm AzureFirstInstall.sh
         ChangeDefaultDir
         sudo rm StratusolveConfigVM.sh
         ;;
    none) echo "Updating Permissions:"
          cd /etc/pam.d/custom-scripts
          ./chPermOwn.sh
          cd
          ;;
esac
