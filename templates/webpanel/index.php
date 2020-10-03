<?php
  
  include_once('header.php');
  $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
  require('Controller/C_showLastImages.php');
  include_once("footer.php") 
?>
