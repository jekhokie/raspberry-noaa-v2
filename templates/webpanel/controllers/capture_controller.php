<?php
  $configs = include('config.php');
  require('models/db_conn.php');
  $db_conn = new Conn($configs->db_dir);
  if ($pass_id < 1) $pass_id = 1;
  $enhancements = $db_conn->getEnhancements($pass_id);
  $path = $db_conn->getImagePath($pass_id);
  require('views/capture.php');
?>
