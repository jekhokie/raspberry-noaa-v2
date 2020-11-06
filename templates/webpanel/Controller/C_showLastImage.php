<?php
  require('Model/Conn.php');
  $con = new Conn();
  $images = $con->getLastImage();
  require('Views/V_viewLastImage.php');
?>
