<?php
  # "Captures" showing grid of all captured images
  include_once('views/header.php');
  $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
  require('controllers/captures_controller.php');
  include_once('views/footer.php') 
?>
