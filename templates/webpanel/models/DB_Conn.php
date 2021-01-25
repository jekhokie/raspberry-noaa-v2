<?php
  class Conn {
    private $con;

    public function __construct(string $db_dir) {
      $this->con = new SQLite3($db_dir . 'panel.db');
    }

    public function getPasses() {
      $today = strtotime(date('Y-m-d', time()));
      $query = $this->con->query("SELECT sat_name,
                                         is_active,
                                         pass_start,
                                         pass_end,
                                         max_elev
                                  FROM predict_passes
                                  WHERE (pass_start > $today)
                                  ORDER BY pass_start ASC;");
      $passes = [];
      $i = 0;

      while($row = $query->fetchArray()) {
        $passes[$i] = $row;
        $i++;
      }

      return $passes;
    }
  }
?>
