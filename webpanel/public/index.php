<?php

# composer auto-loading
require dirname(__DIR__) . '/vendor/autoload.php';

use Config\Config;

# error handling
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

include(__DIR__ . '/../Lib/Router.php');

# handle route dispatching
$router = new Lib\Router();

?>
