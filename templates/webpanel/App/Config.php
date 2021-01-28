<?php

namespace App;

class Config {
  # how many captures to show per page (pagination)
  const CAPTURES_PER_PAGE = 18;

  # base directory for sqlite database
  const DB_DIR = '/home/pi/raspberry-noaa-v2/';

  # see files in App/Lang directory for available translations
  const LANG = 'en';

  # use https://www.php.net/manual/en/timezones.php
  const TIMEZONE = 'America/New_York';
}

?>
