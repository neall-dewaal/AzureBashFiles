#!/bin/bash
#Global Variables
DirectoryPermissionRewriteLocation=/var/www/html #Specify directory for which to rewrite permissions.
OutputFileLocation=/etc/pam.d/custom-scripts/Output.txt #specify your output file here.
StopBashFile=/etc/pam.d/custom-scripts/stopBash.txt #Path to file that allows user to disable folder permissions and ownership rewrite.

#Function: Prints the variable passed into the indicated file
function printInput {
    strOutput=$(date '+%d/%m/%Y %H:%M:%S')
    strOutput="@$strOutput $1"
    echo $strOutput >> $OutputFileLocation
}
#Function: Changes the permissions of the specified file
function runCHMOD {
    Success=1
    chmod -R 775 $DirectoryPermissionRewriteLocation || Success=0
    if [ $Success -eq 1 ]
    then
        printInput 'File permission rewrite->Success'
    elif [ $Success -eq 0 ]
    then
        printInput 'File permission rewrite->Failed'
        printInput 'Script aborted'
        exit 1
    fi
}
#Function: Changes the ownership of the specified file
function runCHOWN {
    Success=1
    chown -R www-data:www-data $DirectoryPermissionRewriteLocation || Success=0
    if [ $Success -eq 1 ]
    then
        printInput 'File ownership rewrite->Success'
    elif [ $Success -eq 0 ]
    then
        printInput 'File ownership rewrite->Failed'
        printInput 'Script aborted'
        exit 1
    fi
}
#Function: Checks the specified file for to stop the bash script
function stopBash {
    read fileLine < $StopBashFile
    chrlen=${#fileLine}
    if [ $chrlen -gt 0 ]
    then
        printInput 'User manually interupted the script. Remove all text from stopBash.txt to enable.'
        exit 1
    fi
}

#Start your logic
if [ "$PAM_TYPE" = "close_session" ]
then
    stopBash
    runCHMOD
    runCHOWN
else
    exit 1
fi