#!/bin/bash

# TODO: Warn the user
BASEPATH="/var/www/wx/image"
FINALPATH="/var/www/wx/images"
SAT_NAMES="NOAA15 NOAA18 NOAA19 METEOR-M2"
DB_PATH="/var/ramfs/panel.db"

cd "$BASEPATH" || exit 1
mkdir -p "$FINALPATH"

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
    if [[ $basename == *"METEOR"* ]]; then
        sqlite3 "$DB_PATH" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",1,0);"
    elif [[ $basename == *"ZA"* ]]; then
        if [[ -f "$FINALPATH/$passname-MSA.jpg" ]]; then
            sqlite3 "$DB_PATH" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",1,1);"
        else
            sqlite3 "$DB_PATH" "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($epoch_date,\"$passname\",0,1);"
        fi
    fi
    echo "Done."
    echo ""
done


