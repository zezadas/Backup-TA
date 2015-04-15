#!/bin/bash
initialize(){
    clear
    echo -e ""
    echo " [ ------------------------------------------------------------]"
    echo " [  Backup TA v%VERSION% for Sony Xperia                       ]"
    echo " [ ------------------------------------------------------------]"
    echo " [  Initialization                                             ]"
    echo " [                                                             ]"
    echo " [  Make sure that you have USB Debugging enabled, you do      ]"
    echo " [  allow your computer ADB access by accepting its RSA key    ]"
    echo " [  (only needed for Android 4.2.2 or higher) and grant this   ]"
    echo " [  ADB process root permissions through superuser.            ]"
    echo " [ ------------------------------------------------------------]"
    echo -e ""
}

cat(){
    $(which cat) $@ |tr -d '\r'
}

dispose_all(){
    cd ..
    echo -e ""
    echo "======================================="
    echo " CLEAN UP"
    echo "======================================="
    unset partition
    unset choiceTextParam
    unset choice
    
    #Backup
    unset backup_currentPartitionMD5
    unset backup_backupMD5
    unset backup_backupPulledMD5
    unset backup_defaultTA
    unset backup_defaultTAvalid
    unset backup_matchOP_ID
    unset backup_matchOP_Name
    unset backup_matchRootingStatus
    unset backup_matchS1_Boot
    unset backup_matchS1_Loader
    unset backup_matchS1_HWConf
    unset backup_taPartitionName
    unset backup_TAByName
    unset partition
    adb shell rm /sdcard/backupTA.img  > /dev/null
    
    #BusyBox
    removeBusyBox

    #Convert
    unset convert_timestamp
    rm -rf convert-this

    #Restore
    unset restore_dryRun
    unset restore_backupMD5
    unset restore_savedBackupMD5
    unset restore_currentPartitionMD5
    unset restore_pushedBackupMD5
    unset restore_restoredMD5
    unset restore_revertedMD5
    unset restore_backupSerial
    unset restore_serialno
    unset partition
    adb shell rm /sdcard/restoreTA.img > /dev/null
    adb shell rm /sdcard/revertTA.img  > /dev/null
    
    rm -rf ./tmpbak

    echo "Killing ADB Daemon..."
    adb kill-server > /dev/null

    echo "OK"
    exit
}


VERSION=9.11
export PARTITION_BY_NAME="/dev/block/platform/msm_sdcc.1/by-name/TA"

source ./scripts/license.sh
source ./scripts/adb.sh
source ./scripts/busybox.sh
source ./scripts/root.sh
source ./scripts/menu.sh

mkdir -p tmpbak 
showLicense
pushBusyBox 
check
if [ "$?" -eq "1" ]
then
    echo "FAILED"
    exit
fi
showMenu
dispose_all

#Happy Hacking


