<?php
  $configs = include('config.php');
  include_once('views/header.php');
  $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
  require('controllers/images_controller.php');
  include_once('views/footer.php') 
?>
