pushBusyBox(){
echo "Pushing Backup TA Tools..."
adb push tools/busybox /data/local/tmp/busybox-backup-ta
adb shell chmod 755 /data/local/tmp/busybox-backup-ta
export BB="LS_COLORS=none /data/local/tmp/busybox-backup-ta"
echo "OK"
}

removeBusyBox(){
echo "Removing Backup TA Tools..."
adb shell rm /data/local/tmp/busybox-backup-ta
unset BB
echo "OK"
}

dispose(){
removeBusyBox
}