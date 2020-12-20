![Raspberry NOAA](header_1600.png)

# Webpanel
Last release includes a PHP webpanel that shows satellite passes for the day and a image grid for every received image.

## Migration
There's a VERY experimental script that migrates the data format from the old way to the new web panel way.
1. Install sqlite3: `sudo apt install sqlite3`
2. Run the migration process: `./migrate_data.sh`

The script will construct the new folder structure as well as insert each pass to the database. The script DOES NOT delete ANY image from the old structure, so you may want to delete them after migration is done.

## Troubleshooting

### Satellite pass dates are wrong!
Adjust the web panel timezone in `/var/www/wx/header.php`
Here's a list of supported timezones: [https://www.php.net/manual/en/timezones.php](https://www.php.net/manual/en/timezones.php)

### Language is wrong!
We support several languages such as Spanish (es), English (en), Arabic (ar), German (de) and Serbian (sr).
Adjust the web panel language in `/var/www/wx/Config.php`
