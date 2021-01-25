<?php
  # "Capture" showing list of all images for a particular capture
  include_once('views/header.php');
  $pass_id = isset($_GET['id']) ? intval($_GET['id']) : 1;
  require('controllers/capture_controller.php');
  include_once('views/footer.php') 
?>
