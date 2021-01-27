<?php

namespace App;

class Config {
  # base directory for sqlite database
  const DB_DIR = '/home/pi/raspberry-noaa/';

  # see files in App/Lang directory for available translations
  const LANG = 'en';

  # use https://www.php.net/manual/en/timezones.php
  const TIMEZONE = 'America/New_York';
}

?>
