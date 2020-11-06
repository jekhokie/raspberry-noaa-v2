<div style="overflow-x:auto;">
<table id="passes">
    <?php
      $row_count=0;
      $col_count=0;
      $baseurl = $configs->base_url;
      foreach ($enhacements as $enhacement) {
        if($row_count%3==0) {
          echo "<tr>";
          $col_count=1;
        }
        echo "<td><div id =\"satimgdiv\"><a href=". $baseurl . $path . $enhacement ."><img id=\"satimg\" src=". $baseurl . "thumb/" . $path . $enhacement ."></img></a></div>";
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
