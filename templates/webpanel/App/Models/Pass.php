<?php

namespace App\Models;

class Pass extends \Lib\Model {
  # get a list of passes
  public function getList() {
    $today = strtotime(date('Y-m-d', time()));
    $query = $this->db_conn->query("SELECT sat_name,
                                           is_active,
                                           pass_start,
                                           pass_end,
                                           max_elev
                                    FROM predict_passes
                                    WHERE (pass_start > $today)
                                    ORDER BY pass_start ASC;");

    $passes = [];
    $i = 0;
    while ($row = $query->fetchArray()) {
      $passes[$i] = $row;
      $i++;
    }

    $this->list = $passes;
  }
}

?>
