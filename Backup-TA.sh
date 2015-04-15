#!/bin/bash
initialize(){
clear
echo '
 [ ------------------------------------------------------------ ]
 [  Backup TA v%VERSION% for Sony Xperia                        ]
 [ ------------------------------------------------------------ ]
 [  Initialization                                              ]
 [                                                              ]
 [  Make sure that you have USB Debugging enabled, you do       ]
 [  allow your computer ADB access by accepting its RSA key     ]
 [  (only needed for Android 4.2.2 or higher) and grant this    ]
 [  ADB process root permissions through superuser.             ]
 [ ------------------------------------------------------------ ]'
    
}

cat(){

$(which cat) $@ |tr -d '\r'

}

VERSION=9.11
export PARTITION_BY_NAME="/dev/block/platform/msm_sdcc.1/by-name/TA"

source ./scripts/license.sh
source ./scripts/adb.sh
source ./scripts/busybox.sh
source ./scripts/root.sh
source ./scripts/menu.sh

#if not exist's, create tmpbak dir
mkdir -p tmpbak 
#showLicense #call license disclaimer

#wakeDevice #wait for device to be plugged
pushBusyBox #install busybox
check
if [ "$?" -eq "1" ]
then
    echo "FAILED"
    exit
fi
showMenu


