  <table id="passes" class="img-grid">
    <?php
      $row_count=0;
      $col_count=0;
      $baseurl = $configs->base_url;
      foreach ($images as $image) {
        if($row_count%3==0) {
          echo "<tr>";
          $col_count=1;
        }
        echo "<td><div id =\"satimgdiv\"><a href=". $baseurl . $image['file_path'] ."><img id=\"satimg\" src=". $baseurl . "thumb/" . $image['file_path'] ."></img></a></div>";
        echo "<ul><li>". $image['sat_name'] ."</li>";
        echo "<li>". date('d/m/Y H:i:s', $image['pass_start']) ."</li></ul></td>";
        if($col_count==3) {
          echo "</tr>";
        }
        $row_count++; 
        $col_count++; 
      }
    ?>
  </table>

</body>
</html>
