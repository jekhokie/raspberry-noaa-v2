<?php
  require('models/DB_Conn.php');
  $db_con = new Conn($configs->db_dir);
  $passes = $db_con->getPasses();
  require('views/PassList.php');
?>
