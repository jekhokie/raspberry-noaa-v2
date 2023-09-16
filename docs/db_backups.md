![Raspberry NOAA](../assets/header_1600_v2.png)

If you are worried about power failures or other data corrupting events, there is an ability to perform automated
database backups for easier recovery of the database. To perform backups nightly and retain 3-days worth of backups
(reasonable timeframe in case restoration is necessary), run the following command, which will cause the backup
script to run after the nightly schedule job (ensuring you get latest captures backed up and there is no conflict
of backing up mid-stream of scheduled passes being recorded):

```bash
# back up database nightly at 12:05AM local and retain 3 copies
cat <(crontab -l) <(echo "5 0 * * * /home/{{ target_user }}/raspberry-noaa-v2/scripts/tools/db_backup.sh") | crontab -
```

Backups will be created in the `db_backups` directory of this framework, with the last 3 days of backup files
persisting while older files being pruned when the script runs. The names of the files follow the format of
`panel.db.<YYYYMMDD>.backup`, where `YYYY` is the year, `MM` is the month, `DD` is the day of when the backup
was taken.

In the case of a failure or corrupt database, simply copy the backup desired over your existing `panel.db` SQL file
like so (for example - obviously updating the filename to the backup filename you wish to use). Note that you should
ensure that there are no scripts/captures running at the time of copy that could be updating the database at the
same time (ideally):

```bash
cp /home/{{ target_user }}/raspberry-noaa-v2/db_backups/panel.db.20210212.backup /home/{{ target_user }}/raspberry-noaa-v2/db/panel.db
```

Following this copy/overwrite, visit your webpanel page and you should see data up to the last write to the
database before it was backed up.
