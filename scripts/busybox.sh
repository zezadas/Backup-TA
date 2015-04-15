#!/bin/bash
pushBusyBox(){
echo "Pushing Backup TA Tools..."
adb start-server > /dev/null
adb push tools/busybox /data/local/tmp/busybox-backup-ta &> /dev/null
adb shell chmod 755 /data/local/tmp/busybox-backup-ta      > /dev/null
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