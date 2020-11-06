<?php
  require('Model/Conn.php');
  $con = new Conn();
  $passes = $con->getPasses();
  require('Views/V_viewPasses.php');
?>
