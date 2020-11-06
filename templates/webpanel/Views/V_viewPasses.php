<div style="overflow-x:auto;">
<table id="passes">
  <tr>
    <th><?php echo $lang['satellite']; ?></th>
    <th><?php echo $lang['pass_start']; ?></th>
    <th><?php echo $lang['pass_end']; ?></th>
    <th><?php echo $lang['max_elev']; ?></th>
  </tr>
  <?php
    foreach ($passes as $pass) {
      if ($pass['is_active'] == false) {
        echo "<tr class='inactive'>";
      } else {
        echo "<tr>";
      }
      echo "<td>". $pass['sat_name'] ."</td>";
      echo "<td>". date('H:i:s', $pass['pass_start']) ."</td>";
      echo "<td>". date('H:i:s', $pass['pass_end']) ."</td>";
      echo "<td>". $pass['max_elev'] ."</td>";
      echo "</tr>";
    }
  ?>
</table>
</div>
