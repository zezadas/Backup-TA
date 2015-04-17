#!/bin/bash
showMenu(){
    echo -e ""
    echo " [ ------------------------------------------------------------ ]"
    echo " [  Backup TA v$VERSION for Sony Xperia                         ]"
    echo " [ ------------------------------------------------------------ ]"
    echo -e ""

    PS3='Please make your decision:'
      
    options=("Backup" "Restore" "Restore dry-run" "Convert TA.img" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Backup")
                backup
                break
                ;;
            "Restore")
                restore
                break
                ;;
            "Restore dry-run")
                restore_dry_run
                break
                ;;
            "Convert TA.img")
                convert
                break
                ;;
            "Quit")
                break
                ;;
            *) echo invalid option;;
        esac
    done
}


backup(){
    source scripts/backup.sh

    echo " ======================================="
    echo "  BACKUP"
    echo " ======================================="
    echo " When you continue Backup TA will perform a backup of the TA partition."
    echo " First it will look for the TA partition by its name. When it can not"
    echo " be found this way it will ask you to perform an extensive search."
    echo " The extensive search will inspect many of the partitions on your device,"
    echo " in the hope to find it and continue with the backup process.   "

    while true; do
        read -p "Are you sure you want to continue?" yn
        case $yn in
            [Nn]* ) exit;;
            * ) backupTA  ; break;;
        esac
    done

}

restore(){
    source scripts/restore.sh
    
    echo -e ""
    echo "======================================="
    echo " RESTORE"
    echo "======================================="
    echo "When you continue Backup TA will perform a restore of a TA partition"
    echo "backup. There will be many integrity checks along the way to make sure"
    echo "a restore will either complete successfully, revert when something goes"
    echo "wrong while restoring or fail before the restore begins because of an"
    echo "invalid backup. There is always a risk when writing to an important"
    echo "partition like TA, but with these safeguards that risk is kept to an"
    echo "absolute minimum." 
    echo -e ""
    
    while true; do
        read -p "Are you sure you want to continue?" yn
        case $yn in
            [Nn]* ) exit;;
            * ) restoreTA ; exit;;
        esac
    done
   
}

restore_dry_run(){
    source scripts/restore.sh

    echo -e ""
    echo "======================================="
    echo " RESTORE DRY-RUN                       "
    echo "======================================="
    echo "When you continue Backup TA will perform the restore of a TA partition   "
    echo "in 'dry-run' mode. This mode performs the restore just like the regular  "
    echo "restore with the exception that it will not do an actual restore of the  "
    echo "backup to the device. It will however perform every integrity check, so  "
    echo "you can test beforehand if your backup is invalid or corrupted.          "
    echo -e ""
   
    while true; do
        read -p "Are you sure you want to continue?" yn
        case $yn in
            [Nn]* ) exit;;
            * )restoreTAdry ; exit;;
        esac
    done
}

convert(){
    source scripts/convert.sh
    echo -e ""
    echo "======================================="
    echo " CONVERT TA.IMG                        "
    echo "======================================="
    echo "When you continue Backup TA will ask you to copy your TA.img file to a location"
    echo "and then convert this backup to make it compatible with the latest version     "
    echo "of Backup TA.                                                                  "
    echo -e ""

    while true; do
        read -p "Are you sure you want to continue?" yn
        case $yn in
            [Nn]* ) exit;;
            * ) convertRawTA ; exit;;
        esac
    done
}
