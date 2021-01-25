<?php
  # "Passes" showing table of all scheduled passes (and landing page)
  include_once('views/header.php');
  $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
  require('controllers/pass_controller.php');
  include_once('views/footer.php')
?>
