#!/bin/bash

### Run as a normal user
if [ $EUID -eq 0 ]; then
    echo "This script shouldn't be run as root."
    exit 1
fi

## import common lib
. "$HOME/.noaa.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/common.sh"


# Free disk space
FREE_DISK="$(df | grep "/dev/root" | awk {'print $3'})"

# This is the original path where images were stored
BASEPATH="/var/www/wx/image"

# Size of the old images folder
IMAGEPATH_SIZE="$(du -s $BASEPATH | awk {'print $1'})"

SPACE_NEEDED="$((IMAGEPATH_SIZE * 2))"

if [ "$SPACE_NEEDED" -gt "$FREE_DISK" ]; then
    echo "You need more free space"
    exit 1
fi

# This is the destination path (AKA the new path)
FINALPATH="/var/www/wx/images"

# This is a list of satellite names
SAT_NAMES="NOAA15 NOAA18 NOAA19 METEOR-M2"

# Here's where the database will live
DB_PATH="${NOAA_HOME}/panel.db"

(
    # To speed up the migration process and
    # reduce the SD card wear, the database
    # operations are done over the RAMFS
    # partition
    cd "${RAMFS_AUDIO}" || exit 1
    sqlite3 "$DB_PATH" < "${NOAA_HOME}/templates/webpanel_schema.sql"
)


cd "$BASEPATH" || exit 1

# The webpanel have thumbnails!
mkdir -p "$FINALPATH/thumb"

# Find all the images
for filename in $(find . -name *.jpg); do
    # Grab just the filename without the yyyy/mm/dd path
    basename="$(echo "$filename" | sed 's~.*/~~')"
    for prefix in $SAT_NAMES; do
        basedate="$(echo "$basename" | sed -e "s/^$prefix//" | cut -f1,2 -d'-' | sed -e "s/-//")"
        if [[ $basename == *"$prefix"* ]]; then
            # Grab the satellite name from the file name
            sat_name=$prefix
        fi
    done
    
    date_normalized=$(echo "$basedate" | sed -e "s/^$sat_name//;s/./&:/12;s/./&:/10;s/./& /8;s/./&\//6;s/./&\//4")
    epoch_date=$(date "+%s" -d "$date_normalized")
    if [[ $basename == *"METEOR"* ]]; then
        # Meteor files have one more dash on its name
        passname=$(echo "$basename" | cut -f1,2,3 -d'-')
    else
        passname=$(echo "$basename" | cut -f1,2 -d'-')
    fi
    echo "Migration in progress: $basename"
    cp "$BASEPATH/$filename" "$FINALPATH"

    # Create thumbnails for old images
    convert -thumbnail 300 "$BASEPATH/$filename" "$FINALPATH/thumb/$basename"
    if [[ $basename == *"METEOR"* ]]; then
        # Insert each pass on the database. Also insert the pass prediction
        sqlite3 "${RAMFS_AUDIO}/panel.db" "INSERT INTO decoded_passes (pass_start, file_path, daylight_pass, is_noaa) VALUES ($epoch_date,\"$passname\",1,0);"
        sqlite3 "${RAMFS_AUDIO}/panel.db" "INSERT OR REPLACE INTO predict_passes (sat_name,pass_start,pass_end,max_elev) VALUES (\"$sat_name\",$epoch_date,$epoch_date,0);"
    elif [[ $basename == *"ZA"* ]]; then
        sqlite3 "${RAMFS_AUDIO}/panel.db" "INSERT OR REPLACE INTO predict_passes (sat_name,pass_start,pass_end,max_elev) VALUES (\"$sat_name\",$epoch_date,$epoch_date,0);"
        if [[ -f "$FINALPATH/$passname-MSA.jpg" ]]; then
            # MSA requires a daylight pass and daylight pass is a column of decoded_passes so this is the way to grab them
            sqlite3 "${RAMFS_AUDIO}/panel.db" "INSERT INTO decoded_passes (pass_start, file_path, daylight_pass, is_noaa) VALUES ($epoch_date,\"$passname\",1,1);"
        else
            sqlite3 "${RAMFS_AUDIO}/panel.db" "INSERT INTO decoded_passes (pass_start, file_path, daylight_pass, is_noaa) VALUES ($epoch_date,\"$passname\",0,1);"
        fi
    fi

    # Move the database file to its final destination
    mv "${RAMFS_AUDIO}/panel.db" "$DB_PATH"
    echo "Done."
    echo ""
done


