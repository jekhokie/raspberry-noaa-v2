  <div style="overflow-x:auto;">
  <table id="passes" class="img-grid">
    <?php
      if ($page > 1) {
        echo "<tr><th><a href=\"?page=" . ($page-1) . "\">" . $lang['prev'] . "</a></th>";
      } else {
        echo "<tr><th></th>";
      }
      echo "<th>" . $lang['page'] . " $page " . $lang['of'] . " $page_count</th>";
      if ($page < $page_count) {
        echo "<th><a href=\"?page=" . ($page+1) . "\">" . $lang['next'] . "</a></th></tr>";
      } else {
        echo "<th></th></tr>";
      }
      $row_count=0;
      $col_count=0;
      $baseurl = $configs->base_url;
      foreach ($images as $image) {
        if($row_count%3==0) {
          echo "<tr>";
          $col_count=1;
        }
        switch($image['sat_type']) {
          case 0: // Meteor-M2
            $ending = "-122-rectified.jpg";
            break;
          case 1: // NOAA
            $ending = "-MCIR.jpg";
            break;
          case 2: // ISS
            $ending = "-0.png";
            break;
        }
        echo "<td><div id =\"satimgdiv\"><a href=". "detail.php?id=" . $image['id'] ."><img id=\"satimg\" src=". $baseurl . "thumb/" . $image['file_path'] . $ending ."></img></a></div>";
        echo "<ul><li>". $image['sat_name'] ."</li>";
        echo "<li> " . $lang['elev'] . ": ". $image['max_elev'] ."°</li>";
        echo "<li>". date('d/m/Y H:i:s', $image['pass_start']) ."</li></ul></td>";
        if($col_count==3) {
          echo "</tr>";
        }
        $row_count++; 
        $col_count++; 
      }
    ?>
  </table>
  </div>
</body>
</html>
