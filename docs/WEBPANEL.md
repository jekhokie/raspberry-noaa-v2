![Raspberry NOAA](../assets/header_1600.png)

# Webpanel
Last release includes a PHP webpanel that shows satellite passes for the day and a image grid for every received image.

## Migration
If you're upgrading from a version of the software that does not yet run a webpanel, please use the following instructions first:
1. Install sqlite3: `sudo apt install sqlite3`
2. Run the migration process: `./migrate_data.sh`

The script will construct the new folder structure as well as insert each pass to the database. The script DOES NOT delete ANY image from the old structure, so you may want to delete them after migration is done.

Following the updates above, you can then migrate to the latest webpanel content using the following script:

1. `update_webpanel.sh`

The script will ensure the images and audio remain in-tact but will replace all other web content.
Any time you intend to get the latest content released, simply run this script and all new content from the repo will be copied to the web directory.

## Troubleshooting

### Satellite pass dates are wrong!
Adjust the web panel timezone in `/var/www/wx/header.php`
Here's a list of supported timezones: [https://www.php.net/manual/en/timezones.php](https://www.php.net/manual/en/timezones.php)

### Language is wrong!
We support several languages such as Spanish (es), English (en), Arabic (ar), German (de) and Serbian (sr).
Adjust the web panel language in `/var/www/wx/Config.php`
