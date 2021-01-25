<?php
  require('models/db_conn.php');
  $db_con = new Conn($configs->db_dir);
  $passes = $db_con->getPasses();
  require('views/pass_list.php');
?>
