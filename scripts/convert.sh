#!/bin/bash
convertRawTA(){

echo -e ""
echo "======================================="
echo " PROVIDE BACKUP                        "
echo "======================================="

mkdir -p convert-this

copyTAFile
}

copyTAFile(){

echo "Copy your 'TA.img' file to the \"convert-this\" folder."
echo -e ""

while true
do
    read -p "Are you ready to continue?" yn
    case $yn in
        [Nn]* ) onConvertCancelled;return;;
        * )  
    if ! [ -f "convert-this/TA.img" ]
    then
        echo -e ""
        echo "There is no 'TA.img' file found inside the 'convert-this' folder."
        else 
        break;
    fi
    esac
done



md5sum convert-this/TA.img | cut -d ' ' -f 1 >convert-this/TA.md5
echo -e ""
echo "======================================="
echo " PACKAGE BACKUP                        "
echo "======================================="
adb shell su -c "$BB date +%Y%m%d.%H%M%S">tmpbak/convert_timestamp
export convert_timestamp=`cat tmpbak/convert_timestamp`
cd convert-this
zip ../backup/TA-backup-$convert_timestamp.zip TA.img TA.md5

if [ "$?" -eq "1" ]
then
    onConvertFailed
else
    onConvertSucess
fi

cd ..

unset filename

}

onConvertSucess(){
    export filename="TA-backup-$convert_timestamp.zip"
    echo -e ""
    echo "*** Convert successful ***"
    echo "*** Your new backup is named '$filename ***"
    echo "*** It can be found at backup ***"
    echo -e ""
}

onConvertCancelled(){
    echo "*** Convert cancelled. ***"
}

onConvertFailed(){
    echo "*** Convert unsuccessful. ***"
}