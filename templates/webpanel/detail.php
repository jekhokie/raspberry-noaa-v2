<?php
  $configs = include('Config.php');
  include_once('header.php');
  $pass_id = isset($_GET['id']) ? intval($_GET['id']) : 1;
  require('Controller/C_showDetail.php');
  include_once("footer.php") 
?>
