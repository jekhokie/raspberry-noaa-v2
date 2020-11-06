<?php
  ini_set('display_errors', 1);
  ini_set('display_startup_errors', 1);
  error_reporting(E_ALL);
  date_default_timezone_set('America/Argentina/Buenos_Aires');
  $page = basename($_SERVER['PHP_SELF']);
  $configs = include('Config.php');
  $lang = $configs->lang;
  include_once('language/' . $lang . '.php');
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <link rel="stylesheet" type="text/css" href="style.css">
  <title><?= isset($PageTitle) ? $PageTitle : "Raspberry NOAA"?></title>
</head>
<body>
<div class="topnav">
  <a class="<?php if($page == 'passes.php'){ echo ' active"';}?>" href="passes.php"><?php echo $lang['passes']; ?></a>
  <a class="<?php if($page == 'index.php' || $page == 'detail.php'){ echo ' active"';}?>" href="index.php"><?php echo $lang['images']; ?></a>
</div>
<div class="container">


