<link rel="stylesheet" type="text/css" href="css/pass_list.css">

<table class="table table-bordered table-sm table-striped" id="passes">
  <thead class="thead-dark">
    <tr class="text-center">
      <th scope="col"><?php echo $lang['satellite']; ?></th>
      <th scope="col"><?php echo $lang['pass_start']; ?></th>
      <th scope="col"><?php echo $lang['pass_end']; ?></th>
      <th scope="col"><?php echo $lang['max_elev']; ?></th>
    </tr>
  </thead>
  <tbody>
    <?php
      $now = date('H:i:s', time());

      # account for no passes currently scheduled
      if (count($passes) <= 0) {
        echo "<tr><td colspan=\"4\" class=\"no-passes\">0 " . $lang['passes'] . "</td></tr>";
      } else {
        foreach ($passes as $pass) {
          $pass_start = date('H:i:s', $pass['pass_start']);
          $pass_end   = date('H:i:s', $pass['pass_end']);

          # gray out anything that has already run or did not run because there
          # was another overlapping capture but is now in the past
          if ($pass['is_active'] == false or $pass_end < $now) {
            echo "<tr class='inactive'>";
          } else {
            echo "<tr>";
          }

          echo "<td scope=\"row\">". $pass['sat_name'] ."</td>";
          echo "<td scope=\"row\" class=\"text-center\">" . $pass_start ."</td>";
          echo "<td scope=\"row\" class=\"text-center\">" . $pass_end . "</td>";
          echo "<td scope=\"row\" class=\"text-center\">" . $pass['max_elev'] ."&#176;</td>";
          echo "</tr>";
        }
      }
    ?>
  </tbody>
</table>
