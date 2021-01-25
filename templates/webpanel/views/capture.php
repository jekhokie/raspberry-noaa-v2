      <link rel="stylesheet" type="text/css" href="css/captures.css">

      <?php
        $col_count=0;
        $i = 0;
        $img_count = count($enhancements);

        foreach ($enhancements as $enhancement) {
          if ($col_count % 3 == 0) {
            echo "<div class=\"card-group capture-image-cards\">";
          }

          # build image path and enhancement text
          $img_path = "/images/" . $path . $enhancement;
          $thumb_path = "/images/thumb/" . $path . $enhancement;
          $enhancement_text = "Unknown";
          preg_match("/-(.*).jpg/", $enhancement, $m);
          if (isset($m[1])) {
            $enhancement_text = $m[1];
          }

          // output image and details, with link to respective enhancement images
          echo "<div class=\"card bg-light m-2 p-2 image-card\">";
          echo "  <a href=\"" . $img_path . "\"><img class=\"card-img-top\" src=\"" . $thumb_path . "\" alt=\"img\"></a>";
          echo "  <div class=\"card-body\">";
          echo "    <p class=\"card-text\">";
          echo "      <strong>Enhancement: </strong>" . $enhancement_text;
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
