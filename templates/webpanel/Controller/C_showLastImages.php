<?php
  require('Model/Conn.php');
  $con = new Conn();
  if ($page < 1) $page = 1;
  $img_per_page = $configs->img_per_page;
  $page_count = $con->totalPages($img_per_page);
  if ($page < 1) $page = 1;
  if ($page > $page_count) $page = $page_count;
  $images = $con->getImages($page, $img_per_page);
  require('Views/V_viewLastImages.php');
?>
