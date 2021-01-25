      <link rel="stylesheet" type="text/css" href="css/images.css">

      <div class="pagination">
        <?php
          if ($page < 1) {
            echo "<a href=\"?page=" . ($page-1) . "\">" . $lang['prev'] . "</a>";
          }
        ?>
      </div> 

      <?php
        $col_count=0;
        $i = 0;
        $img_count = count($images);

        foreach ($images as $image) {
          if ($col_count % 3 == 0) {
            echo "<div class=\"card-group capture-image-cards\">";
          }

          // automatically append filename conventions
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

          # build image path
          $img_path = "/images/thumb/" . $image['file_path'] . $ending;

          // output image and details, with link to respective enhancement images
          echo "<div class=\"card bg-light m-2 p-2 image-card\">";
          echo "  <a href=\"detail.php?id=" . $image['id'] . "\"><img class=\"card-img-top\" src=\"" . $img_path . "\" alt=\"img\"></a>";
          echo "  <div class=\"card-body\">";
          echo "    <h5 class=\"card-title\">" . $image['sat_name'] . "</h5>";
          echo "    <p class=\"card-text\">";
          echo "      <strong>" . $lang['elev'] . ":</strong> " . $image['max_elev'] . "<br>";
          echo "      <strong>" . $lang['pass_start'] . ":</strong> " . date('m/d/Y H:i:s', $image['pass_start']);
          echo "    </p>";
          echo "  </div>";
          echo "</div>";

          $i++;
          $col_count++; 

          if ($col_count % 3 == 0 or $i >= $img_count) {
            echo "</div>";
          }
        }
      ?>
