<?php
  ini_set('display_errors', 1);
  ini_set('display_startup_errors', 1);
  error_reporting(E_ALL);
  $page = basename($_SERVER['PHP_SELF']);
  $configs = include('config.php');
  date_default_timezone_set($configs->timezone);
  $lang = $configs->lang;
  include_once('i18n/' . $lang . '.php');
?>

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">

    <link rel="stylesheet" type="text/css" href="css/header.css">
    <link rel="stylesheet" type="text/css" href="css/footer.css">

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/css/bootstrap.min.css"
                           integrity="sha384-B0vP5xmATw1+K9KRQjQERJvTumQW0nPEzvF6L/Z6nronJ3oUOFUFpCjEUQouq2+l" crossorigin="anonymous">
    <title>Raspberry NOAA V2</title>

    <link rel="shortcut icon" href="assets/web_img/favicon.ico" type="image/x-icon"/>
  </head>
  <body>
    <header class="mb-3">
      <div class="navbar navbar-expand navbar-dark bg-dark">
        <ul class="navbar-nav mr-auto">
          <li class="nav-item <?php if($page == 'index.php'){ echo 'active'; }?>">
            <a class="nav-link" href="index.php"><?php echo $lang['passes']; ?></a>
          </li>
          <li class="nav-item <?php if($page == 'captures.php' or $page == 'capture.php'){ echo 'active'; }?>">
            <a class="nav-link" href="captures.php"><?php echo $lang['captures']; ?></a>
          </li>
        </ul>
        <span class="navbar-text timezone">
          <em>
            <?php echo $configs->timezone; ?><br>
            (UTC<?php echo date('P'); ?>)
          </em>
        </span>
      </div>
    </header>
    <div class="container">
