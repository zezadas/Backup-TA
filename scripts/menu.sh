showMenu(){
echo "[ ------------------------------------------------------------ ]
[  Backup TA v$VERSION for Sony Xperia                             ]
[ ------------------------------------------------------------ ]"
echo -e ""
PS3='Please make your decision:'
  
options=("Backup" "Restore dry-run" "Convert TA.img" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Backup")
            menu_decision
            ;;
        "Restore dry-run")
            echo "you chose choice 2"
            ;;
        "Convert TA.img")
            echo "you chose choice 3"
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
}


menu_decision(){
source scripts/backup.sh
echo " ======================================="
echo "  BACKUP"
echo " ======================================="
echo " When you continue Backup TA will perform a backup of the TA partition."
echo " First it will look for the TA partition by its name. When it can not"
echo " be found this way it will ask you to perform an extensive search."
echo " The extensive search will inspect many of the partitions on your device,"
echo " in the hope to find it and continue with the backup process.   "
 
 backupTA
 
}