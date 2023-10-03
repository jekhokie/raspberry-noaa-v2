<?php

namespace App\Models;

class Pass extends \Lib\Model {
  public $travel_direction;
  public $at_job_id;

  # get a list of passes
  public function getList() {
    $today = strtotime(date('d.m.Y.', time()));
    $query = $this->db_conn->query("SELECT sat_name,
                                           predict_passes.is_active,
                                           predict_passes.pass_start,
                                           predict_passes.pass_end,
                                           predict_passes.max_elev,
                                           predict_passes.pass_start_azimuth,
                                           predict_passes.azimuth_at_max,
                                           predict_passes.direction,
                                           decoded_passes.id
                                    FROM predict_passes
                                    LEFT JOIN decoded_passes
                                      ON predict_passes.pass_start = decoded_passes.pass_start
                                    WHERE (predict_passes.pass_start > $today)
                                    ORDER BY predict_passes.pass_start ASC;");

    $passes = [];
    $i = 0;
    while ($row = $query->fetchArray()) {
      $passes[$i] = $row;
      $i++;
    }

    $this->list = $passes;
  }

  # get a list of active/remaining passes
  public function getActiveList() {
    $today = time();
    $query = $this->db_conn->query("SELECT sat_name,
                                           is_active,
                                           pass_start,
                                           pass_end,
                                           max_elev,
                                           pass_start_azimuth,
                                           azimuth_at_max,
                                           direction,
                                           at_job_id
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

  # get the 'at' job id for the pass having specified pass_start
  public function getATJobId($pass_start) {
    $query = $this->db_conn->prepare('SELECT at_job_id FROM predict_passes WHERE pass_start = ?;');
    $query->bindValue(1, $pass_start);
    $result = $query->execute();
    $res = $result->fetchArray();

    $this->at_job_id = $res['at_job_id'];
  }

  # delete a pass by the epoch start time
  public function deleteByPassStart($pass_start) {
    $query = $this->db_conn->prepare('DELETE FROM predict_passes WHERE pass_start = ?;');
    $query->bindValue(1, $pass_start);
    $result = $query->execute();
  }
}

?>
