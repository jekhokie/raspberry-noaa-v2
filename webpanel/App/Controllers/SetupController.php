<?php

namespace App\Controllers;

use Lib\View;
use Config\Config;

class SetupController extends \Lib\Controller {
  # perform authentication prior to access any admin endpoint
  # NOTE: This is a CHEAP method of security and not recommended as
  #       "sufficient" to enable exposing things on the public internet.
  protected function before() {
    if (Config::LOCK_ADMIN == "true") {
      if (!isset($_SERVER['PHP_AUTH_USER']) ||
          ($_SERVER['PHP_AUTH_USER'] != Config::ADMIN_USER || $_SERVER['PHP_AUTH_PW'] != Config::ADMIN_PASS)) {
        header('WWW-Authenticate: Basic realm="raspberry-noaa-v2"');
        header('HTTP/1.0 401 Unauthorized');
        echo 'Auth required';
        exit;
      }
    }
  }

  public function indexAction($args) {

    View::renderTemplate('Setup/index.php');
  }
}

?>
