<?php
  require('Model/Conn.php');
  $con = new Conn();
  if ($pass_id < 1) $pass_id = 1;
  $enhacements = $con->getEnhacements($pass_id);
  $path = $con->getPath($pass_id);
  require('Views/V_viewDetail.php');
?>
