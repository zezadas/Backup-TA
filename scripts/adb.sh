#!/bin/bash
wakeDevice(){
adb kill-server > /dev/null
adb start-server > /dev/null
echo -e "\nWaiting for USB Debugging...\n"
adb wait-for-device
echo "OK"
}