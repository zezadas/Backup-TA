#!/bin/bash
inspectPartition(){
if [[ "$backup_taPartitionName" =~ "-1" ]]
then
exit
fi

echo "--- $1 ---"
echo "Searching for Operator Identifier..."
adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c 'OP_ID='">tmpbak/backup_matchOP_ID
export backup_matchOP_ID=`cat tmpbak/backup_matchOP_ID`

if [[ "$backup_matchOP_ID" =~ "1" ]]
then
echo "+"
else
echo "-"
fi
echo "Searching for Operator Name..."
adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c 'OP_NAME='">tmpbak/backup_matchOP_Name
export backup_matchOP_Name=`cat tmpbak/backup_matchOP_Name`

if [[ "$backup_matchOP_Name" =~ "1" ]]
then
echo "+"
else
echo "-"
fi
echo "Searching for Rooting Status..."
adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c 'ROOTING_ALLOWED='">tmpbak/backup_matchRootingStatus
export backup_matchRootingStatus=`cat tmpbak/backup_matchRootingStatus`

if [[ "$backup_matchRootingStatus" =~ "1" ]]
then
echo "+"
else
echo "-"
fi

echo "Searching for S1 Boot..."
adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c -i 'S1_Boot'">tmpbak/backup_matchS1_Boot
export backup_matchS1_Boot=`cat tmpbak/backup_matchS1_Boot`

if [[ "$backup_matchS1_Boot" =~ "1" ]]
then
echo "+"
else
echo "-"
fi

echo "Searching for S1 Loader..."
adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c -i 'S1_Loader'">tmpbak/backup_matchS1_Loader
export backup_matchS1_Loader=`cat tmpbak/backup_matchS1_Loader`

if [[ "$backup_matchS1_Loader" =~ "1" ]]
then
echo "+"
else
echo "-"
fi

echo "Searching for S1 Hardware Configuration..."
adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c -i 'S1_HWConf'">tmpbak/backup_matchS1_HWConf
export backup_matchS1_HWConf=`cat tmpbak/backup_matchS1_HWConf`

if [[ "$backup_matchS1_HWConf" =~ "1" ]]
then
echo "+"
else
echo "-"
fi


if [[ "$backup_matchOP_ID" =~ "1" ]]
then

if [[ "$backup_matchOP_Name" =~ "1" ]]
then
if [[ "$backup_matchRootingStatus" =~ "1" ]]
then
if [[ "$backup_matchS1_Boot" =~ "1" ]]
then
if [[ "$backup_matchS1_Loader" =~ "1" ]]
then
if [[ "$backup_matchS1_HWConf" =~ "1" ]]
then
if [ "$backup_taPartitionName" -z ]
then
export backup_taPartitionName=$1
else
export backup_taPartitionName="-1"
fi
fi
fi
fi
fi
fi
fi
}

backupTA(){
echo -e ""

mkdir -p backup  

wakeDevice
echo -e ""
echo "======================================="
echo " FIND TA PARTITION                     "
echo "======================================="

adb shell su -c "$BB ls -l $PARTITION_BY_NAME" | awk '{print $11}'>tmpbak/backup_defaultTA
export backup_defaultTA=`cat tmpbak/backup_defaultTA`

adb shell su -c "if [ -b '$backup_defaultTA' ]; then echo '1'; else echo '0'; fi">tmpbak/backup_defaultTAvalid
export backup_defaultTAvalid=`cat tmpbak/backup_defaultTAvalid`

if [[ "$backup_defaultTAvalid" =~ "1" ]]
then
export partition=$backup_defaultTA
echo "Partition found"
else
echo "Partition not found by name."
while true; do
read -p "Do you want to perform an extensive search for the TA" yn
case $yn in
[Nn]* ) onBackupCancelled;;
* )  break;;
esac
done

echo -e ""
echo "======================================="
echo " INSPECTING PARTITIONS                 "
echo "======================================="

export backup_taPartitionName=

adb shell su -c "$BB cat /proc/partitions | $BB awk '{if (\$3<=9999 && match (\$4, \"'\"mmcblk\"'\")) print \$4}'">tmpbak/backup_potentialPartitions
#adb shell su -c "$BB cat /proc/partitions" | awk '{if ($3 && match ($4, mmcblk)) print $4}'>tmpbak/backup_potentialPartitions
FILE="tmpbak/backup_potentialPartitions"
while read line; do
inspectPartition $line
done < "$FILE"

if ! [ "$backup_taPartitionName" -z ]
then
if ! [[ "$backup_taPartitionName" =~ "-1" ]]
then
echo "echo Partition found!"
export partition="/dev/block/$backup_taPartitionName"
else
echo "*** More than one partition match the TA partition search criteria. ***"
echo "*** Therefore it is not possible to determine which one or ones to use. ***"
echo "*** Contact DevShaft @XDA-forums for support. ***"
onBackupCancelled
fi
else
echo "*** No compatible TA partition found on your device. ***"
onBackupCancelled
fi
fi


echo -e ""
echo "======================================="
echo " BACKUP TA PARTITION                   "
echo "======================================="
adb shell su -c "$BB md5sum $partition" | awk '{print $1}'>tmpbak/backup_currentPartitionMD5
adb shell su -c "$BB dd if=$partition of=/sdcard/backupTA.img"


echo -e ""
echo "======================================="
echo " INTEGRITY CHECK                       "
echo "======================================="

adb shell su -c "$BB md5sum /sdcard/backupTA.img" | awk '{print $1}'>tmpbak/backup_backupMD5
export backup_currentPartitionMD5=`cat tmpbak/backup_currentPartitionMD5`
export backup_backupMD5=`cat tmpbak/backup_backupMD5`

if ! [ "$backup_currentPartitionMD5" == "$backup_backupMD5" ]
then
echo "FAILED - Backup does not match TA Partition. Please try again."
onBackupFailed
else
echo "OK"
fi

echo -e ""
echo "======================================="
echo " PULL BACKUP FROM SDCARD               "
echo "======================================="
adb pull /sdcard/backupTA.img tmpbak/TA.img
if ! [ "$?" -eq "0" ]
then
onBackupFailed
fi


echo -e ""
echo "======================================="
echo " INTEGRITY CHECK                       "
echo "======================================="
md5sum tmpbak/TA.img | cut -d ' ' -f 1 >tmpbak/backup_backupPulledMD5

if ! [ "$?" -eq "0" ]
then
onBackupFailed
fi
export backup_backupPulledMD5=`cat tmpbak/backup_backupPulledMD5`
if ! [ "$backup_currentPartitionMD5" == "$backup_backupPulledMD5" ]
then
echo "FAILED - Backup has gone corrupted while pulling. Please try again."
onBackupFailed
else
echo "OK"
fi

echo -e ""
echo "======================================="
echo " PACKAGE BACKUP                        "
echo "======================================="

adb get-serialno>tmpbak/TA.serial
echo $partition>tmpbak/TA.blk
echo $backup_backupPulledMD5>tmpbak/TA.md5
echo $VERSION>tmpbak/TA.version
adb shell su -c "$BB date +%Y%m%d.%H%M%S">tmpbak/TA.timestamp
export backup_timestamp=`cat tmpbak/TA.timestamp`
cd tmpbak

zip ../backup/TA-backup-$backup_timestamp.zip TA.img TA.md5 TA.blk TA.serial TA.timestamp TA.version
if ! [ "$?" -eq "0" ]
then
onBackupFailed
fi

echo "*** Backup successful. ***"
}

onBackupCancelled(){
echo "*** Backup cancelled. ***"
}

onBackupFailed(){
echo "*** Backup unsuccessful. ***"
}