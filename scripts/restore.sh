#!/bin/bash
hardbrickConfirmation(){
	while true; do
		read -p "This restore may hard-brick your device. Are you sure you want to restore the TA Partition?" yn
		case $yn in
			[Nn]* ) exit;;
			* ) break;;
		esac
	done
}

#####################
## RESTORE DRY
#####################

restoreTAdry(){
	export restore_dryRun="1"
	restoreTA
}

#####################
## RESTORE
#####################

restoreTA(){
	echo -e "\n"
	wakeDevice
	echo -e "\n"
	if [[ "$restore_dryRun" =~ "1" ]]
	then
		echo "--- Restore dry run ---"
	fi
	adb get-serialno>tmpbak/restore_serialno
	export restore_serialno=`cat tmpbak/restore_serialno`

	echo -e ""
	echo "======================================="
	echo "CHOOSE BACKUP TO RESTORE               "
	echo "======================================="
	echo "off" > tmpbak/restore_list
	export restore_restoreIndex="0"

	i=0
	for backup_file in $(ls backup/TA-Backup*.zip)
	do
		echo "$i : $backup_file"
		backup_list[$i]=$backup_file
		(( i++ ))
	done
	echo "$backup_list">restore_list
	restoreChoose
}

restoreChoose(){

	while true
	do
		read -p "Please make your decision:" decision
		if [[ $decision =~ "q" || $decision =~ "Q" ]]
		then
			onRestoreCancelled
			exit
		fi
		if ! [ -z "${backup_list[$decision]}" ]
		then
			export restore_restoreFile=${backup_list[$decision]}
			break
		fi
	done

	echo -e "\n"

	while true; do
		read -p "Are you sure you want to restore $restore_restoreFile?" yn
		case $yn in
			[Nn]* ) onRestoreCancelled;;
			* ) break;;
		esac
	done

	echo -e "\n"
	echo "======================================="
	echo " EXTRACT BACKUP                        "
	echo "======================================="

	unzip "$restore_restoreFile" -d tmpbak
	if [ "$?" -eq "1" ]
	then
		echo "FAILED"
		onRestoreFailed
	fi
	if [ -f tmpbak/TA.blk ]
	then
		export partition=`cat tmpbak/TA.blk`
	else
		adb shell su -c "$BB ls -l $PARTITION_BY_NAME" | awk '{print $11}'>tmpbak/restore_defaultTA
		export restore_defaultTA=`cat tmpbak/restore_defaultTA`
		adb shell su -c "if [ -b '$restore_defaultTA' ]; then echo '1'; else echo '0'; fi">tmpbak/restore_defaultTAvalid
		export restore_defaultTAvalid=`cat tmpbak/restore_defaultTAvalid`
		if [[ "$restore_defaultTAvalid" =~ "1" ]]
		then
			export partition=$PARTITION_BY_NAME
		else
			export partition="/dev/block/mmcblk0p1"
		fi
	fi

	echo -e "\n"
	echo "======================================="
	echo " INTEGRITY CHECK                       "
	echo "======================================="
	export restore_savedBackupMD5=`cat tmpbak/TA.md5`

	md5sum tmpbak/TA.img | cut -d ' ' -f 1 >tmpbak/restore_backupMD5
	
	if [ "$?" -eq "1" ]
	then
		echo "FAILED"
		onRestoreFailed
	fi

	export restore_backupMD5=`cat tmpbak/restore_backupMD5`

	if ! [[ "$restore_savedBackupMD5" =~ "$restore_backupMD5" ]]
	then
		echo "FAILED - Backup is corrupted."
		onRestoreFailed
	else
		echo "OK"
	fi

	echo -e "\n"
	echo "======================================="
	echo " COMPARE TA PARTITION WITH BACKUP      "
	echo "======================================="
	adb shell su -c "$BB md5sum $partition" | awk {'print $1'}>tmpbak/restore_currentPartitionMD5
	export restore_currentPartitionMD5=`cat tmpbak/restore_currentPartitionMD5`

	if [[ "$restore_currentPartitionMD5" =~ "$restore_savedBackupMD5" ]]
	then
		echo "TA partition already matches backup, no need to restore."
		onRestoreCancelled
	else
		echo "OK"
	fi

	echo -e "\n"
	echo "======================================="
	echo " BACKUP CURRENT TA PARTITION           "
	echo "======================================="
	adb shell su -c "$BB dd if=$partition of=/sdcard/revertTA.img"
	adb shell su -c "$BB sync "
	adb shell su -c "$BB sync "
	adb shell su -c "$BB sync "
	adb shell su -c "$BB sync "

	if [ "$?" -eq "1" ]
	then
		echo "FAILED"
		onRestoreFailed
	fi

	adb shell su -c "$BB ls -l /sdcard/revertTA.img" | awk {'print $5'}>tmpbak/restore_revertTASize
	export restore_revertTASize=`cat tmpbak/restore_revertTASize`

	echo -e "\n"
	echo "======================================="
	echo " PUSH BACKUP TO SDCARD                 "
	echo "======================================="
	adb push tmpbak/TA.img sdcard/restoreTA.img

	if [ "$?" -eq "1" ]
	then
		echo "FAILED"
		onRestoreFailed
	fi

	echo -e "\n"
	echo "======================================="
	echo " INTEGRITY CHECK                       "
	echo "======================================="
	adb shell su -c "$BB ls -l /sdcard/restoreTA.img" | awk {'print $5'}>tmpbak/restore_pushedBackupSize
	adb shell su -c "$BB md5sum /sdcard/restoreTA.img" | awk {'print $1'}>tmpbak/restore_pushedBackupMD5

	if [ "$?" -eq "1" ]
	then
		echo "FAILED"
		onRestoreFailed
	fi

	export restore_pushedBackupSize=`cat tmpbak/restore_pushedBackupSize`
	export restore_pushedBackupMD5=`cat tmpbak/restore_pushedBackupMD5`

	if ! [[ "$restore_savedBackupMD5" =~ "$restore_pushedBackupMD5" ]]
	then
		echo "FAILED - Backup has gone corrupted while pushing. Please try again."
		onRestoreFailed
	else
		if ! [[ "$estore_revertTASize" =~ "$restore_pushedBackupSize" ]]
		then
			echo "FAILED - Backup and TA partition sizes do not match."
			onRestoreFailed
		else
			echo "OK"
		fi
	fi

	echo -e "\n"
	echo "======================================="
	echo " SERIAL CHECK                          "
	echo "======================================="
	if ! [ -f tmpbak/TA.serial ]
	then
		adb shell su -c "$BB cat /sdcard/restoreTA.img" |  grep -m 1 $restore_serialno>tmpbak/restore_backupSerial
		if [ "$?" -eq "1" ]
		then
			echo "FAILED"
			unknownDevice
		fi
		cp tmpbak/restore_backupSerial tmpbak/TA.serial 
	fi
	export restore_backupSerial=`cat tmpbak/TA.serial`

	if ! [[ "$restore_serialno" =~ "$restore_backupSerial" ]]
	then
		otherDevice
	fi
	echo "OK"
	validDevice
}

otherDevice(){
	echo "The backup appears to be from another device."
	invalidConfirmation
}
unknownDevice(){
	echo "It is impossible to determine the origin for this backup. The backup could be from another device."
	invalidConfirmation
}

invalidConfirmation(){
	hardbrickConfirmation
	if [ "$?" -eq "1" ]
	then
		echo "FAILED"
		onRestoreCancelled
	fi
	validDevice
}

validDevice(){
	echo -e "\n"
	echo "======================================="
	echo " RESTORE BACKUP                        "
	echo "======================================="
	if ! [[ "$restore_dryRun" =~ "1" ]]
	then
		adb shell su -c "$BB dd if=/sdcard/restoreTA.img of=$partition"
		adb shell su -c "$BB sync "
		adb shell su -c "$BB sync "
		adb shell su -c "$BB sync "
		adb shell su -c "$BB sync "

		if [ "$?" -eq "1" ]
		then
			echo "FAILED"
			onRestoreFailed
		fi

	else
		echo "--- dry run ---"
	fi
	adb shell su -c "rm /sdcard/restoreTA.img"

	echo -e "\n"
	echo "======================================="
	echo " COMPARE NEW TA PARTITION WITH BACKUP  "
	echo "======================================="
	adb shell su -c "$BB md5sum $partition" | awk {'print $1'}>tmpbak/restore_restoredMD5
	if ! [[ "$restore_dryRun" =~ "1" ]]
	then
		export restore_restoredMD5=`cat tmpbak/restore_restoredMD5`

	else
		export restore_restoredMD5=$restore_pushedBackupMD5
	fi
	if [[ "$restore_currentPartitionMD5" =~ "$restore_restoredMD5" ]]
	then
		echo "TA partition appears unchanged, try again."
		onRestoreFailed
	elif ! [[ "$restore_restoredMD5" =~ "$restore_savedBackupMD5" ]]
	then
		echo "TA partition seems corrupted. Trying to revert restore now..."
		onRestoreCorrupt
	else
		echo OK
	fi
	onRestoreSuccess
}

#####################
## RESTORE SUCCESS
#####################
onRestoreSuccess(){
	echo "*** Restore successful. ***1"
	echo "*** You must restart the device for the restore to take effect. *** "
	echo -e "\n"


	read -p "Do you want to restart the device?" reboot_var
	if ! [[ "$reboot_var" =~ "n" || "$reboot_var" =~ "N" ]]
	then
		adb reboot
	fi
}

#####################
## RESTORE CANCELLED
#####################
onRestoreCancelled(){
	echo "*** Restore cancelled. ***"
	exit
}


#####################
## RESTORE FAILED
#####################
onRestoreFailed(){
	echo "*** Restore unsuccessful. ***"
}


#####################
## RESTORE CORRUPT
#####################
onRestoreCorrupt(){
	echo -e "\n"
	echo "======================================="
	echo " REVERT RESTORE                        "
	echo "======================================="
	if ! [[ "$restore_dryRun" =~ "1" ]] 
	then
		adb shell su -c "$BB dd if=/sdcard/revertTA.img of=$partition"
		adb shell su -c "$BB sync "
		adb shell su -c "$BB sync "
		adb shell su -c "$BB sync "
		adb shell su -c "$BB sync "
	fi

	echo -e "\n"
	echo "======================================="
	echo " REVERT VERIFICATION                   "
	echo "======================================="
	adb shell su -c "$BB md5sum $partition" | awk {'print $1'}>tmpbak/restore_revertedMD5
	if ! [[ "$restore_dryRun" =~ "1" ]]
	then
		export restore_revertedMD5=`cat tmpbak/restore_revertedMD5`
	else
		export restore_revertedMD5=$restore_currentPartitionMD5
	fi

	if ! [[ "$restore_currentPartitionMD5" =~ "$restore_revertedMD5" ]]
	then
		echo "FAILED"
		onRestoreRevertFailed
	else
		echo "OK"
		onRestoreRevertSuccess
	fi
}

#####################
## RESTORE REVERT FAILED
#####################
onRestoreRevertFailed(){
	adb pull /sdcard/revertTA.img tmpbak/revertTA.img
	echo "*** DO NOT SHUTDOWN OR RESTART THE DEVICE!!! ***"
	echo "*** Reverting restore has failed! Contact DevShaft @XDA-forums for guidance. ***"
}

#####################
## RESTORE REVERT SUCCESS
#####################
onRestoreRevertSuccess(){
	echo "*** Revert successful. Try to restore again. ***"
}
