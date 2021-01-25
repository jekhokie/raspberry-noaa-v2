<?php
  require('models/db_conn.php');
  $db_conn = new Conn($configs->db_dir);
  $passes = $db_conn->getPasses();
  require('views/pass_list.php');
?>
