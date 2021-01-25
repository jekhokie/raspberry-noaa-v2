<?php
  $img_per_page = 18;

  $configs = include('config.php');
  require('models/db_conn.php');
  $db_conn = new Conn($configs->db_dir);
  $page_count = $db_conn->totalPages($img_per_page);

  # adjust for under/over paging
  if ($page < 1) $page = 1;
  if ($page > $page_count) $page = $page_count;

  $images = $db_conn->getImages($page, $img_per_page);
  require('views/all_captures.php');
?>
