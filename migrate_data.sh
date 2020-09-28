#!/bin/bash

## import common lib
. "$HOME/.noaa.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/common.sh"

# TODO: Warn the user
BASEPATH="/var/www/wx/image"
FINALPATH="/var/www/wx/images"
SAT_NAMES="NOAA15 NOAA18 NOAA19 METEOR-M2"
DB_PATH="${NOAA_HOME}/panel.db"


(
    cd "${RAMFS_AUDIO}" || exit 1
    sqlite3 < "${NOAA_HOME}/panel.sql"
)


cd "$BASEPATH" || exit 1
mkdir -p "$FINALPATH/thumb"

for filename in $(find . -name *.jpg); do
    basename="$(echo "$filename" | sed 's~.*/~~')"
    for prefix in $SAT_NAMES; do
        basedate="$(echo "$basename" | sed -e "s/^$prefix//" | cut -f1,2 -d'-' | sed -e "s/-//")"
        if [[ $basename == *"$prefix"* ]]; then
            sat_name=$prefix
        fi
    done
    
    date_normalized=$(echo "$basedate" | sed -e "s/^$sat_name//;s/./&:/12;s/./&:/10;s/./& /8;s/./&\//6;s/./&\//4")
    epoch_date=$(date "+%s" -d "$date_normalized")
    passname=$(echo "$basename" | cut -f1,2 -d'-')
    echo "Migration in progress: $basename"
    cp "$BASEPATH/$filename" "$FINALPATH"
    convert -thumbnail 300 "$BASEPATH/$filename" "$FINALPATH/thumb/$basename"
    if [[ $basename == *"METEOR"* ]]; then
        sqlite3 "${RAMFS_AUDIO}/panel.db" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",1,0);"
        sqlite3 "${RAMFS_AUDIO}/panel.db" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",1,0);"
        sqlite3 "${RAMFS_AUDIO}/panel.db" "insert or replace into predict_passes (sat_name,pass_start,pass_end,max_elev) values (\"$sat_name\",$epoch_date,$epoch_date,0);"
    elif [[ $basename == *"ZA"* ]]; then
        sqlite3 "${RAMFS_AUDIO}/panel.db" "insert or replace into predict_passes (sat_name,pass_start,pass_end,max_elev) values (\"$sat_name\",$epoch_date,$epoch_date,0);"
        if [[ -f "$FINALPATH/$passname-MSA.jpg" ]]; then
            sqlite3 "${RAMFS_AUDIO}/panel.db" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",1,1);"
        else
            sqlite3 "${RAMFS_AUDIO}/panel.db" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",0,1);"
        fi
    fi
    mv "${RAMFS_AUDIO}/panel.db" "$DB_PATH"
    echo "Done."
    echo ""
done


