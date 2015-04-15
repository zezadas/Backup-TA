#!/bin/bash
check(){
    echo "Requesting root permissions..."
    adb shell su -c "$BB echo true">tmpbak/rootPermission
    export rootPermission=`cat tmpbak/rootPermission`
    if [[ " $rootPermission " =~ "true" ]]
    then
        echo "OK" 
    else
        echo "FAILED"
        exit    
    fi
   
    rm ./tmpbak/rootPermission
}